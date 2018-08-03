using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace KeySender
{
    class Program
    {
        [DllImport("User32.dll")]
        static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        [DllImport("User32.dll")]
        static extern int SetForegroundWindow(IntPtr hWnd);

        static void Main(string[] args)
        {
            IntPtr ptrFF = FindWindow(null, "Chrome");
            SetForegroundWindow(ptrFF);
            SendKeys.SendWait("{F1}");
        }
    }
}
