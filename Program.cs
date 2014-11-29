using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.IO.Ports;
using System.Threading;

namespace ConsoleApplication1
{
    class Program
    {
        static void Main(string[] args)
        {

            SerialPort s = new SerialPort("COM4", 9600);

            s.Open();
            Console.WriteLine("What File? Default init.lua");
            string infile = Console.ReadLine();
            if(string.IsNullOrEmpty(infile))
            {
                infile = "init.lua";
            }
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Files", infile);

            System.IO.StreamReader file =new System.IO.StreamReader(path);
            s.Write("file.remove(\"init.lua\")\r");
            s.Write("file.open(\"init.lua\", \"w\")\r");
            foreach (string line in File.ReadLines(path))
            {
                s.Write("file.writeline([[" + line + "]])\r");
                Console.WriteLine(line);
                Thread.Sleep(150);
            }
            s.Write("file.close()\r");


            s.Close();
            file.Close();

            Console.ReadLine();
            

        }


    }
}
