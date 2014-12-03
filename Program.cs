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

            SerialPort s = new SerialPort("COM3", 9600);

            
            s.Open();
            Console.WriteLine("What Directory? Default Files");
            string infolder = Console.ReadLine();
            if (string.IsNullOrEmpty(infolder))
            {
                infolder = "Files";
            }

            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Files");

            foreach (var item in Directory.GetFiles(path))
            {

                System.IO.StreamReader file = new System.IO.StreamReader(item);
                var fileName = Path.GetFileName(item);

                Console.WriteLine(fileName);

                s.Write(string.Format("file.remove(\"{0}\")\r", fileName));
                s.Write(string.Format("file.open(\"{0}\", \"w\")\r", fileName));
                foreach (string line in File.ReadLines(item))
                {
                    s.Write("file.writeline([[" + line + "]])\r");
                    Console.WriteLine(line);
                    Thread.Sleep(200);
                }
                s.Write("file.close()\r");

                file.Close();
                Console.WriteLine("-------------------");

            }


            s.Close();

            Console.WriteLine("Finished");
            Console.ReadLine();
            

        }


    }
}
