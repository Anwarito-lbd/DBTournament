#!/bin/sh
# Copies the pure Shared modules next to the tests (Luau CLI resolves ./ requires relative to the file) and runs them.
cd "$(dirname "$0")" && mkdir -p _lib && for m in Races Modifiers StatResolver Quests TrainingMath Elo DragonBalls RaidMath StorySchema ToPLogic EpisodeLogic StoryEpisodes; do cp ../src/ReplicatedStorage/Shared/$m.lua _lib/$m.luau 2>/dev/null; done
LUAU=${LUAU:-$(command -v luau || echo /tmp/luau)}
cp ../src/ReplicatedStorage/Shared/Config.lua _lib/Config.luau; cp ../StoryMissions.lua _lib/StoryMissions.luau
for t in run_tests.luau quests_tests.luau config_tests.luau v7_tests.luau v8_tests.luau story_data_tests.luau top_tests.luau episode_tests.luau; do [ -f $t ] && { echo "== $t"; $LUAU $t || exit 1; }; done
