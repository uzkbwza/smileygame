using Godot;

namespace suicide.framework;

using Godot;
using System;
using System.Collections.Generic;

public partial class BestRng : RandomNumberGenerator
{
    public static readonly Vector2I[] CardinalDirs = 
    {
        new Vector2I(1, 0), 
        new Vector2I(0, 1), 
        new Vector2I(-1, 0), 
        new Vector2I(0, -1)
    };
    
    public static readonly Vector2I[] DiagonalDirs = 
    {
        new Vector2I(1, 1), 
        new Vector2I(1, -1), 
        new Vector2I(-1, -1), 
        new Vector2I(-1, 1)
    };

    public static Vector2 Ang2Vec(float angle)
    {
        return new Vector2(Mathf.Cos(angle), Mathf.Sin(angle));
    }

    public Vector2I RandomDir(bool diagonals = false, bool zero = false)
    {
        List<Vector2I> dirs = new List<Vector2I>(CardinalDirs);
        if (diagonals)
        {
            dirs.AddRange(DiagonalDirs);
        }
        if (zero)
        {
            dirs.Add(new Vector2I(0, 0));
        }
        return Choose(dirs.ToArray());
    }

    public BestRng()
    {
        Randomize();
    }

    public Vector2 SpreadVec(Vector2 vec, float spreadDegrees)
    {
        return vec.Rotated(RandfRange(Mathf.DegToRad(-spreadDegrees / 2), Mathf.DegToRad(spreadDegrees / 2)));
    }

    public double RandomAngle()
    {
        return RandfRange(0, Mathf.Tau);
    }

    public double RandomAngleCentered()
    {
        return RandfRange(0, Mathf.Tau) - Mathf.Tau / 2;
    }

    public Vector2I RandomCell(Vector2I start, Vector2I end)
    {
        return new Vector2I(RandiRange(start.X, end.X), RandiRange(start.Y, end.Y));
    }

    public Rect2I RandomRect2i(Vector2I start, Vector2I end, int minWidth = 1, int minHeight = 1, int maxWidth = int.MaxValue, int maxHeight = int.MaxValue)
    {
        Vector2I rectSize = new Vector2I(RandiRange(minWidth, maxWidth), RandiRange(minHeight, maxHeight));
        Vector2I rectStart = RandomCell(start, end - rectSize);
        return new Rect2I(rectStart, rectSize);
    }

    public Vector2 RandomVec(bool normalized = true)
    {
        return Ang2Vec((float)RandomAngle()) * (normalized ? 1 : RandfRange(0, 1));
    }

    public T Choose<T>(T[] array)
    {
        if (array.Length == 0)
        {
            return default(T);
        }
        return array[Randi() % array.Length];
    }

    public int RandSign()
    {
        return Randi() % 2 == 0 ? -1 : 1;
    }

    public bool CoinFlip()
    {
        return Randi() % 2 == 0;
    }

    public Vector2 RandomPointInRect(Rect2 rect)
    {
        return new Vector2(RandfRange(rect.Position.X, rect.End.X), RandfRange(rect.Position.Y, rect.End.Y));
    }

    public int WeightedRandiRange(int start, int end, Func<int, int> weightFunction)
    {
        if (start == end)
        {
            return start;
        }

        float weightSum = 0.0f;
        List<int> weights = new List<int>();
        for (int i = start; i < end; i++)
        {
            int weight = weightFunction(i);
            weights.Add(weight);
            weightSum += weight;
        }

        double rnd = RandfRange(0, weightSum);
        for (int i = start; i < end; i++)
        {
            int weight = weights[i - start];
            if (rnd <= weight)
            {
                return i;
            }
            rnd -= weight;
        }
        throw new Exception("Should never get here");
    }

    public bool Percent(double percent)
    {
        return Chance(percent / 100.0f);
    }

    public bool PercentDelta(double percent, double delta, double max = double.MaxValue)
    {
        return ChanceDelta(percent / 100.0f, delta, max / 100.0f);
    }

    public bool Chance(double n)
    {
        if (n >= 1)
        {
            return true;
        }
        if (n <= 0)
        {
            return false;
        }
        return Randf() < n;
    }

    public bool ChanceDelta(double chance, double delta, double max = double.MaxValue)
    {
        double probabilityAtLeastOne = 1 - Mathf.Exp(-chance * delta);
        return Chance(Mathf.Min(probabilityAtLeastOne, max));
    }

    public T WeightedChoice<T>(T[] array, int[] weightArray)
    {
        return FuncWeightedChoice(array, i => weightArray[i]);
    }

    public T FuncWeightedChoice<T>(T[] array, Func<int, int> weightFunction)
    {
        if (array.Length == 0)
        {
            return default(T);
        }
        return array[WeightedRandiRange(0, array.Length, weightFunction)];
    }
}