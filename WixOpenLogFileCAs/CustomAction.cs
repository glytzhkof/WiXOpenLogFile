using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;
using Microsoft.Deployment.WindowsInstaller;
using System.Windows.Forms;

namespace WixOpenLogFileCAs
{
    public class CustomActions
    {
        [CustomAction]
        public static ActionResult OpenLog(Session session)
        {
            Process.Start("notepad.exe", session["MsiLogFileLocation"]);
            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult ShowMessageBox(Session session)
        {
            MessageBox.Show("Now cancel the setup before dismissing this pop-up to test UserExit dialog.", 
                "Info:", MessageBoxButtons.OK, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button1, 
                MessageBoxOptions.DefaultDesktopOnly);
            session.Log("Begin ShowMessageBox");

            return ActionResult.Success;
        }
    }
}


