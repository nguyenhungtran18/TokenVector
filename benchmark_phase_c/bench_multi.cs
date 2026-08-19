using System;

interface IFlyable
{
    int Fly();
}

class Animal
{
    public int sound;
    public Animal(int sound) { this.sound = sound; }
    public virtual int Speak() { return sound; }
}

class Bird : Animal, IFlyable
{
    public Bird(int sound) : base(sound) { }
    public int Fly() { return sound * 10; }
}

class Program
{
    static int BenchMulti(int n)
    {
        var b = new Bird(3);
        int total = 0;
        int i = 0;
        while (i < n)
        {
            total = total + ((b.Speak() + b.Fly()) % 1000);
            i = i + 1;
        }
        return total;
    }

    static void Main(string[] args)
    {
        int n = int.Parse(args[0]);
        Console.WriteLine(BenchMulti(n));
    }
}
