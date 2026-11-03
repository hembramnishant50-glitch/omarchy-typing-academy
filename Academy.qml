import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtMultimedia
import qs.Commons
import "components"
import "ui"
import "tabs"
import "Model.js" as Model
import "Lessons.js" as Lessons
import "Words.js" as Words
import "Code.js" as Code

// The Academy root. omarchy-shell owns the window lifecycle: the bar widget
// asks the shell to toggle this plugin, the shell calls open()/close() here,
// and dismiss() hands the close back to the shell so its open-state ledger
// stays honest.
//
// One rule shapes the whole file: the profile is never mutated in place. All
// writes go through commit(), which deep-clones, mutates the clone, and then
// assigns the clone to `profile`. QML re-evaluates every binding that reads
// `profile` exactly once per save, which keeps the tabs honest without any
// manual refresh plumbing.
Item {
  id: academy

  // Injected by omarchy-shell.
  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  property bool opened: false

  // When false the layer surface stops at the bar, so the shell bar stays
  // visible and clickable. When true the window covers the whole screen.
  property bool fullScreen: false

  // "tabs" shows the browser; "practice" hands the screen to PracticeView.
  property string view: "tabs"
  property string tab: "learn"

  readonly property var tabNames: ["learn", "drills", "speed", "keyboard", "games", "progress", "settings"]

  // Raw key sink for the games tab. A game needs Space, Backspace and every
  // letter, so it gets first refusal before the Academy's own shortcuts.
  property var keySink: null

  // The run currently loaded into PracticeView:
  // { kind, id, title, subtitle, text, targetWpm, targetAcc, timeLimit, testMode, amount }
  property var session: null
  property string gameMode: "falling"

  property string toastText: ""
  property bool toastVisible: false

  property bool profileLoaded: false
  property var profile: Model.emptyProfile()

  readonly property string dataDir: Quickshell.env("HOME") + "/.local/share/omarchy/typing-academy"
  readonly property string profilePath: dataDir + "/profile.json"

  // Cached reads so a binding on `profile` can stay a plain property instead
  // of a function call in every tab.
  readonly property var settings: profile.settings
  readonly property var level: Model.levelInfo(profile.xp)
  readonly property int streak: Model.liveStreak(profile)

  readonly property string nextLessonId: {
    if (!academy.session || academy.session.kind !== "lesson") return ""
    var next = Lessons.nextLesson(academy.profile)
    if (!next || next.id === academy.session.id) return ""
    return next.id
  }

  readonly property bool practiceVisible: view === "practice"

  // ------------------------------------------------------------- lifecycle

  function open(payloadJson) {
    var args = {}
    if (payloadJson) {
      try { args = JSON.parse(payloadJson) || {} } catch (e) { args = {} }
    }

    opened = true
    fullScreen = false
    view = "tabs"
    session = null
    if (keySink) keySink = null
    if (args.tab !== undefined) openTab(String(args.tab))
    Qt.callLater(focusCatcher)
  }

  function close() {
    if (keySink) keySink = null
    session = null
    view = "tabs"
    opened = false
    writeProfile()
  }

  function dismiss() {
    close()
    if (shell && typeof shell.hide === "function") {
      shell.hide((manifest && manifest.id) || "nishant.typing-academy")
    }
  }

  function toggle() {
    if (opened) dismiss()
    else open("{}")
  }

  // Hosts that instantiate the overlay already open (harnesses) still get a
  // usable surface.
  Component.onCompleted: {
    if (opened) open("{}")
  }

  onOpenedChanged: {
    if (opened) Qt.callLater(focusCatcher)
  }

  function focusCatcher() {
    if (catcher) catcher.forceActiveFocus()
  }

  // Resizing the layer surface can rebuild it, which drops keyboard focus, so
  // every path that toggles full screen re-claims focus afterwards.
  function toggleFullScreen() {
    fullScreen = !fullScreen
    Qt.callLater(focusCatcher)
  }

  // ------------------------------------------------------------------- tabs

  function openTab(name) {
    var wanted = String(name || "")
    if (tabNames.indexOf(wanted) === -1) wanted = "learn"
    if (keySink) keySink = null
    tab = wanted
    view = "tabs"
    Qt.callLater(focusCatcher)
  }

  function cycleTab(delta) {
    var index = tabNames.indexOf(tab)
    if (index < 0) index = 0
    var count = tabNames.length
    openTab(tabNames[(index + (delta || 1) + count) % count])
  }

  function backToTabs() {
    if (keySink) keySink = null
    view = "tabs"
    session = null
    Qt.callLater(focusCatcher)
  }

  // ---------------------------------------------------------------- sessions

  function startLesson(id) {
    var lesson = Lessons.find(String(id || ""))
    if (!lesson) {
      toast("Lesson not found")
      return
    }
    var stage = Lessons.stageFor(lesson.stage)
    session = {
      kind: "lesson",
      id: lesson.id,
      title: lesson.title,
      subtitle: (stage ? stage.title + " · " : "") + "aim for " + lesson.targetWpm + " wpm at " +
                lesson.targetAcc + "% accuracy",
      text: lesson.text,
      targetWpm: lesson.targetWpm,
      targetAcc: lesson.targetAcc,
      timeLimit: 0,
      testMode: "lesson",
      amount: 0
    }
    beginSession()
  }

  function startDrill(text, title, subtitle) {
    if (!text || text.length < 4) {
      toast("That drill came back empty")
      return
    }
    session = {
      kind: "drill",
      id: "drill",
      title: title || "Drill",
      subtitle: subtitle || "Targeted practice",
      text: String(text),
      targetWpm: 0,
      targetAcc: 0,
      timeLimit: 0,
      testMode: "drill",
      amount: 0
    }
    beginSession()
  }

  function startTest() {
    var s = profile.settings
    var mode = s.testMode
    var amount = Math.max(10, Math.round(s.testAmount))
    var text = ""
    var subtitle = ""
    var limit = 0
    var opts = { punctuation: s.punctuation === true, numbers: s.numbers === true }

    if (mode === "code") {
      var snippet = Code.makeSnippet(s.codeLang)
      text = snippet.text
      subtitle = snippet.name + " · symbols exact, no autocomplete"
      amount = 0
    } else if (mode === "quote") {
      var quote = Words.makeQuote(s.quoteLength)
      text = quote.text
      subtitle = quote.who ? quote.who : "A passage from the collection"
      amount = 0
    } else if (mode === "words") {
      text = Words.makeWords(amount, opts)
      subtitle = amount + " words · punctuation and numbers follow your settings"
    } else {
      text = Words.makeWords(Math.max(80, Math.ceil(amount * 7)), opts)
      limit = amount
      subtitle = amount + " seconds on the clock"
    }

    session = {
      kind: "test",
      id: "test",
      title: "Speed test",
      subtitle: subtitle,
      text: text,
      targetWpm: 0,
      targetAcc: 0,
      timeLimit: limit,
      testMode: mode,
      amount: amount
    }
    beginSession()
  }

  // Enter is the keyboard equivalent of the "start" button on the tab that
  // owns one. A typing app should be usable without reaching for the mouse.
  function primaryAction() {
    if (view !== "tabs") return false

    if (tab === "learn") {
      var next = Lessons.nextLesson(profile)
      if (!next) {
        toast("Every lesson is done — take a speed test")
        return true
      }
      startLesson(next.id)
      return true
    }

    if (tab === "drills" && tabLoader.item && typeof tabLoader.item.startDefault === "function") {
      tabLoader.item.startDefault()
      return true
    }

    if (tab === "speed") {
      startTest()
      return true
    }

    if (tab === "games" && keySink && typeof keySink.start === "function") {
      keySink.start()
      return true
    }

    return false
  }

  function beginSession() {
    view = "practice"
    // Deferred so the text binding lands before the restart; two assignments
    // of the same passage would otherwise leave the old cursor in place.
    Qt.callLater(function () {
      if (!practice) return
      practice.restart()
      practice.focusTyping()
    })
  }

  function recordSession(outcome) {
    if (!session || !outcome) return
    var kind = session.kind
    var next = Model.clone(profile)
    var passed = false

    if (kind === "lesson") {
      passed = outcome.acc >= Math.max(88, session.targetAcc - 8)
      Model.recordLesson(next, session.id, withExtra(outcome, { passed: passed }))
    } else if (kind === "drill") {
      Model.recordDrill(next, outcome)
    } else {
      Model.recordTest(next, withExtra(outcome, {
        mode: session.testMode || "time",
        amount: session.amount || 0
      }))
    }

    var unlocked = Model.evaluate(next, {
      lessonsDone: Lessons.completedCount(next),
      lessonsTotal: Lessons.LESSONS.length
    })

    profile = next
    scheduleSave()
    playWin()
    announce(unlocked)

    if (kind === "lesson") {
      if (passed) toast("Lesson complete — " + Math.round(outcome.wpm) + " wpm")
      else toast("Accuracy " + Math.round(outcome.acc) + "% — " + Math.round(Math.max(88, session.targetAcc - 8)) + "% needed to move on")
    } else if (kind === "test") {
      toast(Math.round(outcome.wpm) + " wpm at " + Math.round(outcome.acc) + "%")
    }
  }

  function recordGame(gameId, result) {
    if (!result) return
    var next = Model.clone(profile)
    Model.recordGame(next, String(gameId || gameMode), result)
    var unlocked = Model.evaluate(next, {
      lessonsDone: Lessons.completedCount(next),
      lessonsTotal: Lessons.LESSONS.length
    })
    profile = next
    scheduleSave()
    playWin()
    announce(unlocked)
  }

  function withExtra(source, extra) {
    var out = {}
    var k
    for (k in source) out[k] = source[k]
    for (k in extra) out[k] = extra[k]
    return out
  }

  function announce(ids) {
    if (!ids || ids.length === 0) return
    var first = Model.achievementById(ids[0])
    if (!first) return
    toast("Achievement: " + first.name + (ids.length > 1 ? " (+" + (ids.length - 1) + ")" : ""))
  }

  // --------------------------------------------------------------- settings

  function setSetting(key, value) {
    if (!key) return
    var next = Model.clone(profile)
    next.settings[key] = value
    next.settings = Model.normalizeSettings(next.settings)
    profile = next
    scheduleSave()
  }

  function resetProgress() {
    var keep = Model.clone(profile.settings)
    var fresh = Model.emptyProfile()
    fresh.settings = keep
    profile = fresh
    scheduleSave()
    toast("Progress erased")
    if (view !== "tabs") backToTabs()
  }

  // ---------------------------------------------------------------- feedback

  function toast(message) {
    if (!message) return
    toastText = String(message)
    toastVisible = true
    toastTimer.restart()
  }

  function playKey(ok) {
    if (!profile.settings.sound) return
    var effect = ok ? clickSound : errorSound
    effect.volume = profile.settings.volume
    effect.play()
  }

  function playWin() {
    if (!profile.settings.sound) return
    winSound.volume = profile.settings.volume
    winSound.play()
  }

  // ------------------------------------------------------------- key routing

  // Returns true when the event was consumed. Handled inside the catcher's
  // Keys handler, so an unhandled key simply does nothing rather than
  // leaking into the compositor.
  function handleKey(event) {
    if (keySink && typeof keySink.handleKey === "function") {
      if (keySink.handleKey(event)) return true
    }

    if (event.key === Qt.Key_F11) {
      toggleFullScreen()
      return true
    }

    if (event.key === Qt.Key_Escape) {
      if (view === "practice") backToTabs()
      else dismiss()
      return true
    }

    if (view === "tabs" && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      if (primaryAction()) return true
    }

    if (event.modifiers & Qt.ControlModifier) {
      if (event.key >= Qt.Key_1 && event.key <= Qt.Key_7) {
        openTab(tabNames[event.key - Qt.Key_1])
        return true
      }
      if (event.key === Qt.Key_Tab) {
        cycleTab(1)
        return true
      }
    }

    if (view !== "practice" || !practice) return false

    if (event.key === Qt.Key_Backspace) {
      practice.backspace()
      return true
    }

    var ch = event.text
    if (ch && ch.length === 1 && ch.charCodeAt(0) >= 32) {
      practice.press(ch)
      return true
    }

    return false
  }

  // -------------------------------------------------------------------- data

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", academy.dataDir]
    running: true
    onExited: academy.dirReady = true
  }

  // Set by the mkdir process; declared after it so the binding order is
  // obvious when reading the file.
  property bool dirReady: false

  FileView {
    id: profileFile
    path: academy.profilePath
    atomicWrites: true
    watchChanges: false
    printErrors: false
    onLoaded: academy.loadProfile(text())
    onLoadFailed: academy.profileLoaded = true
  }

  Timer {
    id: saveTimer
    interval: 350
    repeat: false
    onTriggered: academy.writeProfile()
  }

  Timer {
    id: toastTimer
    interval: 2400
    repeat: false
    onTriggered: academy.toastVisible = false
  }

  function scheduleSave() {
    if (!profileLoaded) return
    saveTimer.restart()
  }

  function writeProfile() {
    if (!profileLoaded) return
    if (!dirReady) {
      saveTimer.restart()
      return
    }
    profileFile.setText(JSON.stringify(profile, null, 2) + "\n")
  }

  function loadProfile(raw) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "")) } catch (e) { parsed = null }
    profile = parsed ? Model.migrate(parsed) : Model.emptyProfile()
    profileLoaded = true
  }

  // ------------------------------------------------------------------ sounds

  SoundEffect {
    id: clickSound
    source: Qt.resolvedUrl("assets/click.wav")
  }

  SoundEffect {
    id: errorSound
    source: Qt.resolvedUrl("assets/error.wav")
  }

  SoundEffect {
    id: winSound
    source: Qt.resolvedUrl("assets/win.wav")
  }

  // ------------------------------------------------------------------ window

  // Height of the bar the window should stay clear of. Read from the shell's
  // bar state, so a hidden bar or a bottom bar behaves sensibly instead of
  // leaving a phantom gap.
  readonly property bool barAtTop: !shell || !shell.bar || String(shell.bar.position || "top") === "top"
  readonly property int barInset: {
    if (fullScreen) return 0
    if (!shell || !shell.bar) return 0
    if (shell.bar.barHidden === true) return 0
    return Math.max(0, shell.bar.barSize || 0)
  }

  PanelWindow {
    id: panel
    visible: academy.opened
    anchors { top: true; bottom: true; left: true; right: true }
    margins {
      top: academy.barAtTop ? academy.barInset : 0
      bottom: academy.barAtTop ? 0 : academy.barInset
    }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-typing-academy"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: academy.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Clicking the gap around the window is the mouse equivalent of Escape.
    MouseArea {
      anchors.fill: parent
      onClicked: academy.dismiss()
    }

    Rectangle {
      id: sheet

      // Windowed: sit inside the screen with a gap all round. Full screen:
      // overscan by a few pixels, because the layer surface can land on a
      // fractional device pixel and leave a sliver of wallpaper showing along
      // the bottom and right edges.
      x: academy.fullScreen ? -3 : Style.gapsOut
      y: academy.fullScreen ? -3 : Style.gapsOut
      width: parent.width - x * 2
      height: parent.height - y * 2
      radius: 0
      color: Color.background
      border.width: 1
      border.color: Util.alpha(Color.foreground, 0.14)
      clip: true

      // ---------------------------------------------------------------- header

      Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Style.space(22)
        anchors.rightMargin: Style.space(16)
        anchors.topMargin: Style.space(14)
        height: Style.space(38)

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(10)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Typing Academy"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.letterSpacing: -0.4
          }

          Chip {
            anchors.verticalCenter: parent.verticalCenter
            label: "level " + academy.level.level
            interactive: false
            active: true
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: academy.streak > 0
            text: academy.streak + " day streak"
            color: Util.alpha(Color.accent, 0.86)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(10)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !academy.practiceVisible
            text: "esc closes · ctrl+1–7 tabs · enter starts"
            color: Util.alpha(Color.foreground, 0.58)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }

          TextButton {
            label: academy.fullScreen ? "Exit full screen" : "Full screen"
            onClicked: academy.toggleFullScreen()
          }

          TextButton {
            label: "Close"
            onClicked: academy.dismiss()
          }
        }
      }

      // -------------------------------------------------------------- tab bar

      Item {
        id: tabBar
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Style.space(22)
        anchors.rightMargin: Style.space(22)
        anchors.topMargin: Style.space(8)
        height: Style.space(30)

        Flow {
          width: parent.width
          spacing: Style.space(5)

          Repeater {
            model: academy.tabNames

            delegate: Chip {
              id: tabChip
              required property var modelData
              required property int index
              label: ["Learn", "Drills", "Speed test", "Keyboard", "Games", "Progress", "Settings"][tabChip.index]
              active: academy.view === "tabs" && academy.tab === tabChip.modelData
              onClicked: academy.openTab(tabChip.modelData)
            }
          }
        }
      }

      // --------------------------------------------------------------- content

      Item {
        id: content
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Style.space(22)
        anchors.rightMargin: Style.space(18)
        anchors.topMargin: Style.space(12)
        anchors.bottomMargin: Style.space(14)

        // Browse and configure.
        Loader {
          id: tabLoader
          anchors.fill: parent
          visible: !academy.practiceVisible
          active: !academy.practiceVisible
          sourceComponent: academy.componentFor(academy.tab)
          onLoaded: {
            if (item) item.width = width
            if (item) item.height = height
          }
        }

        // Type. This instance survives tab changes so a finished result card
        // does not flicker away when the loader swaps pages.
        Item {
          id: practiceHost
          anchors.fill: parent
          visible: academy.practiceVisible

          PracticeView {
            id: practice
            anchors.fill: parent
            title: academy.session ? academy.session.title : ""
            subtitle: academy.session ? academy.session.subtitle : ""
            text: academy.session ? academy.session.text : ""
            mode: academy.session ? academy.session.kind : "lesson"
            strict: academy.settings.strict
            timeLimit: academy.session ? academy.session.timeLimit : 0
            targetWpm: academy.session ? academy.session.targetWpm : 0
            targetAcc: academy.session ? academy.session.targetAcc : 0
            showKeyboard: academy.settings.showKeyboard
            showLiveWpm: academy.settings.liveWpm
            showLiveAcc: academy.settings.liveAcc
            caretBlink: academy.settings.caretBlink
            caretStyle: academy.settings.caretStyle
            fontScale: academy.settings.fontSize
            keyStats: academy.profile.keys
            nextLabel: academy.nextLessonId.length > 0 ? "Next lesson" : ""
            showBack: true
            backLabel: academy.session && academy.session.kind === "test" ? "Done" : "Academy"
            onKeystroke: function (ok, ch) { academy.playKey(ok) }
            onFinished: function (outcome) { academy.recordSession(outcome) }
            onNextRequested: {
              if (academy.nextLessonId.length > 0) academy.startLesson(academy.nextLessonId)
              else academy.backToTabs()
            }
            onBackRequested: academy.backToTabs()
            onKeyDrillRequested: function (key) {
              var label = key === " " ? "space" : key
              academy.startDrill(Words.makeKeyDrill([key], 180), "Key drill · " + label,
                                 "Repairing " + label + " — same finger, same key, no hunt")
            }
            onFocusRequested: academy.focusCatcher()
          }
        }
      }

      // ---------------------------------------------------------------- toast

      Rectangle {
        id: toastBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.space(20)
        width: toastLabel.implicitWidth + Style.space(30)
        height: Style.space(32)
        radius: 0
        color: Util.alpha(Color.background, 0.97)
        border.width: 1
        border.color: Util.alpha(Color.accent, 0.36)
        opacity: academy.toastVisible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 160 } }

        Text {
          id: toastLabel
          anchors.centerIn: parent
          text: academy.toastText
          color: Util.alpha(Color.foreground, 0.90)
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }

      // Keyboard catcher. It sits above the content as a sibling but paints
      // nothing, so it neither blocks clicks nor intercepts the pointer.
      Item {
        id: catcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: function (event) {
          if (academy.handleKey(event)) event.accepted = true
        }
      }
    }
  }

  // ------------------------------------------------------------- tab factory

  // Inline components keep every tab in the plugin's module graph, which the
  // shell's loader cannot resolve for bare strings. The switch is a function
  // so each tab is created only when selected.
  function componentFor(name) {
    if (name === "drills") return drillsTab
    if (name === "speed") return speedTab
    if (name === "keyboard") return keyboardTab
    if (name === "games") return gamesTab
    if (name === "progress") return progressTab
    if (name === "settings") return settingsTab
    return learnTab
  }

  Component { id: learnTab; LearnTab { app: academy } }
  Component { id: drillsTab; DrillTab { app: academy } }
  Component { id: speedTab; SpeedTab { app: academy } }
  Component { id: keyboardTab; KeyboardTab { app: academy } }
  Component { id: gamesTab; GamesTab { app: academy } }
  Component { id: progressTab; ProgressTab { app: academy } }
  Component { id: settingsTab; SettingsTab { app: academy } }
}
