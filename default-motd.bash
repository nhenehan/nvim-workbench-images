#!/bin/bash
# chaotic-motd.sh
# Print a random chaos-themed MOTD

# Only print if interactive terminal
if [ -t 1 ]; then
    MOTDS=(
        "🪓 Beware! Chaos inside this container.\n💀 Rust + Julia + Neovim loaded.\n🧨 Hot reload your sanity at your own risk."
        "☣️ Danger: unstable dev environment\n⚡ Plugins and LSP enabled\n🕳️ Dive into the abyss of code"
        "☄️ Projects orbiting in Rust & Julia universes\n🛸 Alien plugins detected\n🩸 Your code may mutate unpredictably"
        "🧟 Zombie processes walking around\n🪤 Debug traps set\n🧛 Night-time coding enabled"
        "🎭 Welcome to your chaotic playground\n🪞 Reflect on your mistakes\n🦦 Everything is fine… probably"
    )

    INDEX=$(( RANDOM % ${#MOTDS[@]} ))
    echo -e "${MOTDS[$INDEX]}"
fi

