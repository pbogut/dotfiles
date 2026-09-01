import QtQuick
import qs.Common

QtObject {
    function check(done) {
        Proc.runCommand(
            "batteryConservation.checkIdeapadCm",
            ["which", "ideapad-cm"],
            (_stdout, exitCode) => {
                if (exitCode !== 0) {
                    done({
                        "title": "ideapad-cm is required",
                        "details": "Install the ideapad-cm command, then enable this plugin again."
                    });
                    return;
                }

                Proc.runCommand(
                    "batteryConservation.checkPkexec",
                    ["which", "pkexec"],
                    (_pkexecStdout, pkexecExitCode) => {
                        if (pkexecExitCode === 0) {
                            done(null);
                            return;
                        }
                        done({
                            "title": "pkexec is required",
                            "details": "Install Polkit and a graphical authentication agent, then enable this plugin again."
                        });
                    },
                    0
                );
            },
            0
        );
    }
}
