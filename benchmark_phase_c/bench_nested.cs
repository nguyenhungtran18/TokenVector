using System;

class Program
{
    static int MakeDeep(int aParam)
    {
        int a = aParam;
        Func<int, int> mid = (bParam) =>
        {
            int b = bParam;
            Func<int, int> inner = (c) => a + b + c;
            return inner(10);
        };
        return mid(1);
    }

    static int BenchNested(int n)
    {
        int total = 0;
        int i = 0;
        while (i < n)
        {
            total = total + (MakeDeep(i) % 1000);
            i = i + 1;
        }
        return total;
    }

    static void Main(string[] args)
    {
        int n = int.Parse(args[0]);
        Console.WriteLine(BenchNested(n));
    }
}
