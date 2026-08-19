using System;

class Circle
{
    public float r;
    public Circle(float r) { this.r = r; }
    public float area { get { return 3.0f * r * r; } }
}

class Program
{
    static float BenchProperty(int n)
    {
        var c = new Circle(2.0f);
        float total = 0.0f;
        int i = 0;
        while (i < n)
        {
            total = total + c.area;
            i = i + 1;
        }
        return total;
    }

    static void Main(string[] args)
    {
        int n = int.Parse(args[0]);
        Console.WriteLine(BenchProperty(n));
    }
}
