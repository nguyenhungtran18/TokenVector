using System;

class Program
{
    static int DoubleIt(int x) { return x * 2; }

    static Func<int, int> Compose(Func<int, int> f)
    {
        int extra = 10;
        Func<int, int> wrapped = delegate(int x) { return f(x) + extra; };
        return wrapped;
    }

    static int BenchB3(int n)
    {
        var g = Compose(DoubleIt);
        int total = 0;
        int i = 0;
        while (i < n)
        {
            total = total + (g(i) % 1000);
            i = i + 1;
        }
        return total;
    }

    static void Main(string[] args)
    {
        int n = int.Parse(args[0]);
        Console.WriteLine(BenchB3(n));
    }
}
