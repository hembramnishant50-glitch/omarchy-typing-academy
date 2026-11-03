import QtQuick
import qs.Commons
import "../components"
import "../Model.js" as Model
import "../Lessons.js" as Lessons

// The long view: level, streaks, totals, the last four weeks of practice, the
// test trend, and the achievement wall.
//
// Everything here is derived from the profile on each read, so this tab never
// caches. That keeps it honest after a reset.
Item {
  id: root

  property var app

  readonly property var profile: app ? app.profile : null
  readonly property var stats: profile ? profile : Model.emptyProfile()
  readonly property var level: Model.levelInfo(stats.xp)
  readonly property var stageList: Lessons.STAGES
  readonly property var week: Model.daySeries(stats, 28)

  readonly property double avg: Model.averageWpm(stats, 10)
  readonly property int tests: Model.recentTests(stats, 80).length
  // Lessons, drills and tests all feed best.wpm / best.acc, so a best is only
  // meaningful once something has actually been typed.
  readonly property int runs: stats.counters.lessons + stats.counters.drills + stats.counters.tests
  readonly property var history: Model.recentTests(stats, 30)

  // "1 lessons" is the kind of detail that makes a progress page feel machine
  // written. Every count on this page goes through here.
  // The latest run from today, if any — it is the one that can clear the
  // daily goal.
  function todayResult() {
    var out = null
    for (var i = 0; i < root.history.length; i++) {
      var entry = root.history[i]
      if (Model.dayKey(entry.ts) === Model.todayKey()) out = entry
    }
    return out
  }

  function dailyCleared() {
    return Model.dailyGoalMet(root.stats, root.todayResult())
  }

  function plural(n, word) {
    return n + " " + word + (n === 1 ? "" : "s")
  }

  function unlockedCount() {
    var n = 0
    for (var i = 0; i < Model.ACHIEVEMENTS.length; i++) {
      if (stats.achievements[Model.ACHIEVEMENTS[i].id] !== undefined) n += 1
    }
    return n
  }

  function stageStats(stage) {
    var items = Lessons.lessonsIn(stage.id)
    var done = 0
    var stars = 0
    for (var i = 0; i < items.length; i++) {
      var rec = stats.lessons ? stats.lessons[items[i].id] : null
      if (rec && rec.done) done += 1
      if (rec && rec.done) stars += Lessons.starsFor(rec)
    }
    return { done: done, total: items.length, stars: stars, seats: items.length * 3 }
  }

  PageScroll {
    anchors.fill: parent

    // ----------------------------------------------------------------- level

    Card {
      width: parent.width
      title: "Level " + root.level.level
      hint: root.plural(root.stats.counters.lessons, "lesson") + " · " +
            root.plural(root.stats.counters.tests, "test") + " · " +
            root.plural(root.stats.counters.drills, "drill") + " · " +
            root.plural(root.stats.counters.games, "game")

      Item {
        width: parent.width
        height: Style.space(12)

        Meter {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          thickness: Style.space(6)
          value: root.level.progress
        }
      }

      Item {
        width: parent.width
        height: Style.space(18)

        Text {
          anchors.left: parent.left
          text: Math.round(root.level.into) + " / " + Math.round(root.level.span) + " xp to level " + (root.level.level + 1)
          color: Util.alpha(Color.foreground, 0.64)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          anchors.right: parent.right
          text: Model.formatCount(root.stats.counters.keys) + " keys typed"
          color: Util.alpha(Color.foreground, 0.54)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    // ----------------------------------------------------------------- stats

    Flow {
      width: parent.width
      spacing: Style.space(10)

      Repeater {
        model: [
          {
            value: root.runs > 0 ? String(Math.round(root.stats.best.wpm)) : "—",
            unit: root.runs > 0 ? "wpm" : "",
            label: root.runs > 0 ? "personal best" : "personal best, no runs yet"
          },
          {
            value: root.tests > 0 ? String(Math.round(root.avg)) : "—",
            unit: root.tests > 0 ? "wpm" : "",
            label: root.tests > 0 ? "average of last 10 tests" : "average, no tests yet"
          },
          {
            value: root.runs > 0 ? String(Math.round(root.stats.best.acc)) + "%" : "—",
            unit: "",
            label: "best accuracy"
          },
          {
            value: String(Model.liveStreak(root.stats)),
            unit: Model.liveStreak(root.stats) === 1 ? "day" : "days",
            label: "current streak"
          },
          {
            value: String(root.stats.bestStreak),
            unit: root.stats.bestStreak === 1 ? "day" : "days",
            label: "longest streak"
          },
          { value: Model.formatDuration(root.stats.counters.seconds), unit: "", label: "time practised" }
        ]

        delegate: Card {
          id: statCard
          required property var modelData
          width: (parent.width - Style.space(20)) / 3

          Stat {
            value: statCard.modelData.value
            unit: statCard.modelData.unit
            label: statCard.modelData.label
            valueSize: Style.font.heading
          }
        }
      }
    }

    // ---------------------------------------------------------- daily goal

    Card {
      width: parent.width
      title: "Daily goal"
      hint: root.dailyCleared()
        ? "Cleared today — bonus banked."
        : "Clear a speed test against today's goal to bank the bonus."

      Item {
        width: parent.width
        height: Style.space(18)

        Text {
          anchors.left: parent.left
          width: parent.width
          text: {
            var r = root.todayResult()
            var out = "No test today yet — take one to set the pace."
            if (root.dailyCleared()) {
              out = "Cleared — " + (r ? Math.round(r.wpm) + " wpm at " + Math.round(r.acc) + "%" : "goal met")
            } else if (r) {
              var s = root.stats
              var st = (s && s.settings) ? s.settings : Model.defaultSettings()
              var gWpm = Number(st.dailyGoalWpm)
              var gAcc = Number(st.dailyGoalAcc)
              out = "Latest run " + Math.round(r.wpm) + " wpm at " + Math.round(r.acc) + "% — goal " + Math.round(gWpm) + " wpm / " + Math.round(gAcc) + "%"
            }
            return out
          }
          color: Util.alpha(Color.foreground, 0.72)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Text {
          anchors.right: parent.right
          text: "streak " + Model.liveStreak(root.stats) + (Model.liveStreak(root.stats) === 1 ? " day" : " days")
          color: Util.alpha(Color.foreground, 0.54)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    // -------------------------------------------------------------- activity

    Card {
      width: parent.width
      title: "Last four weeks"
      hint: "One bar per day. Height is how long you practised, so a row of tall bars is the only evidence that matters."

      Row {
        width: parent.width
        spacing: Math.max(2, Style.space(2))

        Repeater {
          model: root.week

          delegate: Item {
            id: dayBar
            required property var modelData
            required property int index

            readonly property int level: Model.activityLevel(dayBar.modelData.sec)
            readonly property bool today: dayBar.index === root.week.length - 1

            width: Math.max(3, (parent.width - 27 * Math.max(2, Style.space(2))) / 28)
            height: Style.space(56)

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: dayBar.level === 0
                ? Math.max(3, Style.space(3))
                : Math.max(Style.space(6), parent.height * (dayBar.level / 4))
              radius: 0
              color: dayBar.level === 0
                ? Util.alpha(Color.foreground, 0.07)
                : Util.alpha(Color.accent, 0.20 + dayBar.level * 0.18)

              Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
            }

            Rectangle {
              visible: dayBar.today
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.bottomMargin: -Style.space(4)
              height: 1
              color: Util.alpha(Color.foreground, 0.54)
            }
          }
        }
      }

      Item {
        width: parent.width
        height: Style.space(16)

        Text {
          anchors.left: parent.left
          text: root.week.length > 0 ? root.week[0].label : ""
          color: Util.alpha(Color.foreground, 0.52)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          anchors.right: parent.right
          text: "today"
          color: Util.alpha(Color.foreground, 0.52)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Text {
        width: parent.width
        text: Model.practicedToday(root.stats)
          ? "Practised today — streak " + Model.liveStreak(root.stats) + " day" + (Model.liveStreak(root.stats) === 1 ? "" : "s")
          : "Nothing logged today. A single lesson keeps the streak alive."
        color: Model.practicedToday(root.stats)
          ? Util.alpha(Color.accent, 0.90)
          : Util.alpha(Color.foreground, 0.40)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    // ----------------------------------------------------------------- trend

    Card {
      width: parent.width
      title: "Speed over time"
      hint: root.history.length > 1
        ? "Trend " + (Model.trend(root.stats, 10) >= 0 ? "+" : "") + Model.trend(root.stats, 10).toFixed(1) + " wpm across your recent tests."
        : "Take a few speed tests and the shape of your progress appears here."

      LineChart {
        width: parent.width
        height: Style.space(130)
        values: root.history.map(function (t) { return t.wpm })
      }

      Item {
        width: parent.width
        height: Style.space(18)

        Text {
          anchors.left: parent.left
          text: root.history.length > 0 ? Math.round(root.history[0].wpm) + " wpm" : "—"
          color: Util.alpha(Color.foreground, 0.58)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          anchors.right: parent.right
          text: root.history.length > 0
            ? Math.round(root.history[root.history.length - 1].wpm) + " wpm, latest"
            : ""
          color: Util.alpha(Color.foreground, 0.58)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    // ---------------------------------------------------------------- stages

    Card {
      width: parent.width
      title: "Curriculum"
      hint: "Stars are earned against each lesson's own speed and accuracy target."

      Repeater {
        model: root.stageList

        delegate: Item {
          id: stageRow
          required property var modelData

          readonly property var stats: root.stageStats(stageRow.modelData)

          width: parent.width
          height: Style.space(34)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(150)
            text: stageRow.modelData.title
            color: Util.alpha(Color.foreground, 0.72)
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Meter {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(156)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(104)
            anchors.verticalCenter: parent.verticalCenter
            thickness: Style.space(4)
            value: stageRow.stats.total > 0 ? stageRow.stats.done / stageRow.stats.total : 0
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: stageRow.stats.done + "/" + stageRow.stats.total + "  ·  " +
                  stageRow.stats.stars + "/" + stageRow.stats.seats + " ★"
            color: Util.alpha(Color.foreground, 0.66)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }
    }

    // ---------------------------------------------------------- achievements

    Card {
      width: parent.width
      title: "Achievements"
      hint: root.unlockedCount() + " of " + Model.ACHIEVEMENTS.length + " unlocked."

      Flow {
        width: parent.width
        spacing: Style.space(8)

        Repeater {
          model: Model.ACHIEVEMENTS

          delegate: Rectangle {
            id: badge
            required property var modelData

            readonly property bool earned: root.stats.achievements[badge.modelData.id] !== undefined

            width: Math.max(Style.space(150), (parent.width - Style.space(16)) / 3)
            height: Style.space(52)
            radius: 0
            color: Util.alpha(badge.earned ? Color.accent : Color.foreground, badge.earned ? 0.07 : 0.02)
            border.width: 1
            border.color: Util.alpha(badge.earned ? Color.accent : Color.foreground, badge.earned ? 0.26 : 0.07)

            Column {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: Style.space(9)
              spacing: Style.space(2)

              Text {
                width: parent.width
                text: badge.earned ? badge.modelData.name : "Locked"
                color: badge.earned ? Color.foreground : Util.alpha(Color.foreground, 0.30)
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: badge.modelData.desc
                color: Util.alpha(Color.foreground, badge.earned ? 0.66 : 0.46)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }
            }

            HoverHandler { id: badgeHover }

            Rectangle {
              visible: badgeHover.hovered && !badge.earned
              anchors.fill: parent
              radius: 0
              color: Util.alpha(Color.background, 0.92)
              border.width: 1
              border.color: Util.alpha(Color.foreground, 0.12)

              Text {
                anchors.centerIn: parent
                width: parent.width - Style.space(16)
                horizontalAlignment: Text.AlignHCenter
                text: badge.modelData.hint
                color: Util.alpha(Color.foreground, 0.70)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }
        }
      }
    }
  }
}
