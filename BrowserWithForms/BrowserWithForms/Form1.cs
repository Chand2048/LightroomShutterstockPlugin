using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;

namespace BrowserWithForms
{
     public partial class Form1 : Form
    {
        [DllImport("User32.dll")]
        static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("User32.dll")]
        static extern int SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindowEx(IntPtr parentHandle, IntPtr childAfter, string className, string windowTitle);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowText(IntPtr hWnd, StringBuilder strText, int maxCount);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowTextLength(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

        // Delegate to filter which windows to include 
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumChildWindows(IntPtr window, EnumWindowsProc callback, IntPtr lParam);


        /// <summary> Get the text for the window pointed to by hWnd </summary>
        public static string GetWindowText(IntPtr hWnd)
        {
            int size = GetWindowTextLength(hWnd);
            if (size > 0)
            {
                var builder = new StringBuilder(size + 1);
                GetWindowText(hWnd, builder, builder.Capacity);
                return builder.ToString();
            }

            return String.Empty;
        }

        /// <summary> Find all windows that match the given filter </summary>
        /// <param name="filter"> A delegate that returns true for windows
        ///    that should be returned and false for windows that should
        ///    not be returned </param>
        public static IEnumerable<IntPtr> FindWindows(EnumWindowsProc filter)
        {
            IntPtr found = IntPtr.Zero;
            List<IntPtr> windows = new List<IntPtr>();

            EnumWindows(delegate (IntPtr wnd, IntPtr param)
            {
                if (filter(wnd, param))
                {
                    // only add the windows that pass the filter
                    windows.Add(wnd);
                }

                // but return true here so that we iterate all windows
                return true;
            }, IntPtr.Zero);

            return windows;
        }

        public static IEnumerable<IntPtr> FindAllChildWindows(IntPtr parent)
        {
            IntPtr found = IntPtr.Zero;
            List<IntPtr> windows = new List<IntPtr>();

            EnumChildWindows(parent, delegate(IntPtr wnd, IntPtr param)
            {
                windows.Add(wnd);
                // but return true here so that we iterate all windows
                return true;
            }, IntPtr.Zero);

            return windows;
        }

        /// <summary> Find all windows that contain the given title text </summary>
        /// <param name="titleText"> The text that the window title must contain. </param>
        public static IEnumerable<IntPtr> FindWindowsWithText(string titleText)
        {
            return FindWindows(delegate (IntPtr wnd, IntPtr param)
            {
                return GetWindowText(wnd).Contains(titleText);
            });
        }

        public Form1()
        {
            InitializeComponent();
        }



        private void button1_Click(object sender, EventArgs e)
        {

            foreach (IntPtr win in FindWindowsWithText("Google Chrome"))
            {
                SetForegroundWindow(win);
                SendKeys.SendWait("^t");
                SendKeys.SendWait("https://submit.shutterstock.com/api/content_editor/media/P1037710735");
                SendKeys.SendWait("{ENTER}");

                //SendKeys.SendWait("+{TAB}");
                //SendKeys.SendWait("+{TAB}");

                Thread.Sleep(2000);
                SendKeys.SendWait("%n"); // alt+n
                
                SendKeys.SendWait("^a");
                SendKeys.SendWait("^c");

                break;
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            foreach (IntPtr win in FindWindowsWithText("Google Chrome"))
            {
                SetForegroundWindow(win);
                SendKeys.SendWait("^t");
                SendKeys.SendWait("https://submit.shutterstock.com/catalog_manager/images/1037710735");
                SendKeys.SendWait("{ENTER}");

                Thread.Sleep(7000);
                for (int i = 0; i < 69; ++i)
                {
                    SendKeys.SendWait("{TAB}");
                }

                SendKeys.SendWait("^a");
                SendKeys.SendWait("^c");

                SendKeys.SendWait(this.textBox1.Text);
                break;
            }
        }
    }
}