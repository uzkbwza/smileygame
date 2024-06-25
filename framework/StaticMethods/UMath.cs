using System;
using Godot.NativeInterop;

namespace suicide.framework.StaticMethods;

using static Math;
using Godot;

public static class UMath 
{
       public static double Map(this double value, double istart, double istop, double ostart, double ostop)
    {
        return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
    }

    public static double MapPow(this double value, double istart, double istop, double ostart, double ostop, double power)
    {
        return ostart + (ostop - ostart) * (double)Math.Pow((value - istart) / (istop - istart), power);
    }

    public static Vector2 Ang2Vec(this double angle)
    {
        return new Vector2((float)Math.Cos(angle), (float)Math.Sin(angle));
    }

    public static double DtLerp(this double power, double delta)
    {
        return 1 - (double)Math.Pow(Math.Pow(0.1, power), delta);
    }

    public static double EaseOut(this double num, double pow)
    {
        if (num < 0 || num > 1) throw new ArgumentException("num must be between 0 and 1 inclusive");
        return 1.0f - (double)Math.Pow(1.0f - num, pow);
    }

    public static double LerpClamp(this double t, double a, double b)
    {
        return Math.Clamp(t, 0.0f, 1.0f) * (b - a) + a;
    }

    public static double InverseLerpClamp(this double v, double a, double b)
    {
        return Math.Clamp((v - a) / (b - a), 0.0f, 1.0f);
    }

    public static double AngleDiff(this double from, double to)
    {
        return (double)(((to - from + Math.PI) % (2 * Math.PI)) - Math.PI);
    }

    public static double Splerp(this double a, double b, double delta, double halfLife)
    {
        return b + (a - b) * (double)Math.Pow(2, -delta / (halfLife / 60));
    }

    public static Vector2 SplerpVec(this Vector2 a, Vector2 b, float delta, float halfLife)
    {
        return b + (a - b) * (float)Math.Pow(2, -delta / (halfLife / 60));
    }

    public static double Damp(this double source, double target, double smoothing, double dt)
    {
        return Mathf.Lerp(source, target, UMath.DtLerp(smoothing, dt));
    }

    public static double DampAngle(this double source, double target, double smoothing, double dt)
    {
        return Mathf.Lerp(source, target, 1 - (double)Math.Pow(smoothing, dt));
    }

    public static Vector2 DampVec2(this Vector2 source, Vector2 target, float smoothing, float dt)
    {
        return source.Lerp(target, 1 - (float)Math.Pow(smoothing, dt));
    }

    public static Vector3 DampVec3(this Vector3 source, Vector3 target, double smoothing, double dt)
    {
        return source.Lerp(target, 1 - (float)Math.Pow(smoothing, dt));
    }

    public static Vector2 VecDir(this Vector2 vec1, Vector2 vec2)
    {
        return (vec2 - vec1).Normalized();
    }

    public static double Sin01(this double value)
    {
        return (double)(Math.Sin(value) / 2.0) + 0.5f;
    }

    public static Vector2 ClampCell(this Vector2 cell, int mapWidth, int mapHeight)
    {
        return new Vector2(
            Math.Clamp(cell.X, 0, mapWidth - 1),
            Math.Clamp(cell.Y, 0, mapHeight - 1)
        );
    }

    public static double Stepify(this double s, double step)
    {
        return (double)Math.Round(s / step) * step;
    }

    public static double Wave(this double from, double to, double duration, double offset = 0)
    {
        var t = (double)DateTime.UtcNow.Subtract(DateTime.UnixEpoch).TotalSeconds;
        var a = (to - from) * 0.5f;
        return from + a + (double)Math.Sin(((t + duration * offset) / duration) * (2 * Math.PI)) * a;
    }

    public static bool Pulse(double duration = 1.0f, double width = 0.5f)
    {
        return UMath.Wave(0.0f, 1.0f, duration) < width;
    }

    public static double Snap(this double value, double step)
    {
        return (double)Math.Round(value / step) * step;
    }

    public static double Approach(this double a, double b, double amount)
    {
        if (a < b)
        {
            a += amount;
            if (a > b)
            {
                return b;
            }
        }
        else
        {
            a -= amount;
            if (a < b)
            {
                return b;
            }
        }
        return a;
    } 
}