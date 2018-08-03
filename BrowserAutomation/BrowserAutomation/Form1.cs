using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Security.Permissions;

namespace BrowserAutomation
{
    [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            // this.webBrowser1.Url = new Uri("https://www.shutterstock.com/");
            this.webBrowser1.AllowNavigation = true;
            this.webBrowser1.AllowWebBrowserDrop = false;
            this.webBrowser1.IsWebBrowserContextMenuEnabled = true;
            this.webBrowser1.ScriptErrorsSuppressed = false;
            
            this.webBrowser1.Url = new Uri("https://submit.shutterstock.com/dashboard?language=en");
        }
       }
}
