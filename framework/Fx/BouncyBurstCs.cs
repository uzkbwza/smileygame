using System.Linq;
using suicide.framework.StaticMethods;

namespace suicide.framework.Fx;

using Godot;
using Godot.Collections;
using System;
using System.Collections.Generic;

[Tool]
public partial class BouncyBurstCs : Node2D
{
    private const int WIDTH = 1;

    [Export] public int NumBodies { get; set; } = 100;
    [Export(PropertyHint.Layers2DPhysics)] public uint CollisionMask { get; set; } = 1;
    [Export(PropertyHint.Layers2DPhysics)] public uint CollisionLayer { get; set; } = 0;
    [Export] public bool Autostart { get; set; } = false;

    [ExportCategory("Line Properties")]
    [Export(PropertyHint.Range, "1, 100, or_greater")]
    public int SegmentCount { get; set; } = 2;

    [Export] public Color Color { get; set; } = Colors.White;

    [Export] public bool DynamicPointCount { get; set; } = true;

    [Export(PropertyHint.Range, "0.0, 10.0, 0.25, or_greater")]
    public double JitterAmount { get; set; } = 0.0f;

    [Export(PropertyHint.Range, "0.0, 50.0, 1, or_greater")]
    public double QuantizeAmount { get; set; } = 0.0f;

    [ExportCategory("Start Behavior")]
    [Export(PropertyHint.Range, "0.0, 2000, 0.5, or_greater")]
    public double StartingVelocity { get; set; } = 500.0f;

    [Export(PropertyHint.Range, "0.0, 2000, 0.5, or_greater")]
    public double StartingVelocityDeviation { get; set; } = 100.0f;

    [Export(PropertyHint.Range, "0.0, 100.0, 0.5, or_greater")]
    public double MaxStartingDistance { get; set; } = 2.0f;

    [Export(PropertyHint.Range, "0.0, 2000, 0.5, or_greater")]
    public double MinSpeed { get; set; } = 0.0f;

    [ExportCategory("Body Properties")]
    [Export(PropertyHint.Range, "0.0, 1.0, 0.001, or_greater")]
    public double Bounce { get; set; } = 0.4f;

    [Export(PropertyHint.Range, "0.0, 1.0, 0.001, or_greater")]
    public double Friction { get; set; } = 0.05f;

    [Export(PropertyHint.Range, "0.0, 10.0, 0.0001, or_greater")]
    public double Mass { get; set; } = 0.05f;

    [Export(PropertyHint.Range, "-1.0, 100.0, 0.005, or_greater, or_less")]
    public double Damp { get; set; } = 0.0f;

    [Export(PropertyHint.Range, "-10.0, 10.0, 0.1")]
    public double GravityScale { get; set; } = 1.0f;

    [Export] public PhysicsServer2D.CcdMode ContinuousCD { get; set; } = PhysicsServer2D.CcdMode.CastRay;
    [Export] public bool FreezeRotation { get; set; } = true;
    [Export] public double Lifetime { get; set; } = 0.0f;

    [ExportCategory("Bias")]
    [Export(PropertyHint.Range, "0, 1")]
    public double DirectionBiasAmount { get; set; } = 0.0f;

    [Export(PropertyHint.Range, "0, 1")]
    public double VelocityBiasAmount { get; set; } = 0.0f;

    [Export(PropertyHint.Range, "0, 10, 0.001, or_greater")]
    public double VelocityBiasMultiplier { get; set; } = 1.0f;

    [Export(PropertyHint.Range, "0, 50, 0.5, or_greater")]
    public double VelocityBiasPower { get; set; } = 2.0f;

    [Export(PropertyHint.Range, "0, 1")]
    public double IgnoreBiasEffectChance { get; set; } = 0.0f;

    private bool _px1Mode = false;
    private bool _initialized = false;
    private bool _biasActive = false;
    private bool _finished = false;
    private int _numLeft = 0;

    private Vector2 _biasDir;
    private Rid _collisionShape;
    private PhysicsServer2D.BodyMode _physicsMode;
    private List<Rid> _bodies = new();
    private List<Rid> _bodiesToRemove = new();
    private Array<Vector2[]> _lines = new ();
    private BestRng _rng = new();

    private int RealNumPoints
    {
        get
        {
            if (!DynamicPointCount)
                return SegmentCount * 2;

            double fps = Engine.MaxFps <= 0 ? DisplayServer.ScreenGetRefreshRate() : Math.Min(DisplayServer.ScreenGetRefreshRate(), Engine.MaxFps);
            double mod = fps / 60.0f;

            return Math.Max((int)Math.Floor(UMath.Stepify(SegmentCount * mod * 2, 2)), 2);
        }
    }

    public override void _Ready()
    {
        SetProcess(false);

        if (Engine.IsEditorHint())
            return;

        if (Autostart)
            go();
    }

    private void go()
    {
        if (Lifetime > 0)
            GetTree().CreateTimer(Lifetime).Timeout += QueueFree;

        if (_initialized)
            return;

        _Initialize();
        SetProcess(true);
    }

    public override void _Process(double delta)
    {
        if (!_initialized) 
            return;
        
        _CleanupBodies();

        QueueRedraw();
        
        if (_finished && !IsQueuedForDeletion())
            QueueFree();
    }

    private void _DrawLines()
    {
;
    }

    private void _CleanupBodies()
    {
        foreach (var body in _bodiesToRemove)
        {
            int index = _bodies.IndexOf(body);
            PhysicsServer2D.FreeRid(body);
            _bodies.RemoveAt(index);
            _lines.RemoveAt(index);
        }
        _bodiesToRemove.Clear();
    }
    private void _Initialize()
    {
        _biasActive = DirectionBiasAmount > 0 || VelocityBiasAmount > 0;
        _biasDir = Vector2.Right.Rotated(GlobalRotation);
        GlobalRotation *= 0;

        _physicsMode = FreezeRotation ? PhysicsServer2D.BodyMode.RigidLinear : PhysicsServer2D.BodyMode.Rigid;
        _collisionShape = PhysicsServer2D.CircleShapeCreate();
        PhysicsServer2D.ShapeSetData(_collisionShape, WIDTH / 2.0f);

        int numSegments = RealNumPoints;
        var worldSpace = GetWorld2D().Space;

        for (int id = 0; id < NumBodies; id++)
        {
            var body = _CreateBody(worldSpace);
            var line = new Vector2[numSegments * 2];
            for (int pointId = 0; pointId < numSegments * 2; pointId++)
            {
                line[pointId] = (Vector2.Zero);
            }

            _lines.Add(line);
            _bodies.Add(body);
        }

        _numLeft = NumBodies;

        _initialized = true;
    }

    private Rid _CreateBody(Rid space)
    {
        var body = PhysicsServer2D.BodyCreate();
        PhysicsServer2D.BodySetMode(body, _physicsMode);
        PhysicsServer2D.BodyAddShape(body, _collisionShape);
        PhysicsServer2D.BodySetParam(body, PhysicsServer2D.BodyParameter.Mass, Mass);
        PhysicsServer2D.BodySetSpace(body, space);
        PhysicsServer2D.BodySetState(body, PhysicsServer2D.BodyState.Transform, Transform.Translated(_rng.RandomVec(false) * (float)MaxStartingDistance));
        PhysicsServer2D.BodySetParam(body, PhysicsServer2D.BodyParameter.Bounce, Bounce);
        PhysicsServer2D.BodySetParam(body, PhysicsServer2D.BodyParameter.Friction, Friction);
        PhysicsServer2D.BodySetParam(body, PhysicsServer2D.BodyParameter.GravityScale, GravityScale);
        PhysicsServer2D.BodySetParam(body, PhysicsServer2D.BodyParameter.LinearDamp, Damp);
        PhysicsServer2D.BodySetContinuousCollisionDetectionMode(body, ContinuousCD);
        PhysicsServer2D.BodySetState(body, PhysicsServer2D.BodyState.Sleeping, false);

        bool ignoreBias = !_biasActive || _rng.Chance(IgnoreBiasEffectChance);
        double speed = StartingVelocity + _rng.Randfn(0, (float)StartingVelocityDeviation);
        Vector2 impulse = _rng.RandomVec();

        if (!ignoreBias)
        {
            if (_rng.Chance(DirectionBiasAmount))
                impulse = impulse.Lerp(_biasDir, (float)DirectionBiasAmount);

            double newSpeed = speed * (Mathf.Pow(UMath.Map(impulse.Dot(_biasDir), -1, 1, 0, 1), VelocityBiasPower) * VelocityBiasMultiplier);
            speed = Mathf.Lerp(speed, newSpeed, VelocityBiasAmount);
        }

        speed = Mathf.Max(speed, MinSpeed);

        PhysicsServer2D.BodyApplyImpulse(body, impulse * (float)speed * Scale.X);
        PhysicsServer2D.BodySetCollisionMask(body, CollisionMask);
        PhysicsServer2D.BodySetCollisionLayer(body, CollisionLayer);

        return body;
    }
    public void Kill()
    {
        foreach (var body in _bodies)
            PhysicsServer2D.FreeRid(body);
        
        if (_collisionShape != null)
            PhysicsServer2D.FreeRid(_collisionShape);

        _bodies.Clear();
    }

    public override void _Draw()
    {
        if (Engine.IsEditorHint())
        {
            DrawLine(new Vector2(-10, 0), new Vector2(20, 0), Colors.Red, 1.0f);
            DrawLine(new Vector2(0, -10), new Vector2(0, 10), Colors.Blue, 1.0f);
        }

        if (!_initialized)
        {
            return;
        }
        
        bool jitter = JitterAmount > 0;
        bool quantize = QuantizeAmount > 0;
        _finished = true;

        for (int id = 0; id < _numLeft; id++)
        {
            var body = _bodies[id];

            if ((bool)PhysicsServer2D.BodyGetState(body, PhysicsServer2D.BodyState.Sleeping))
            {
                _bodiesToRemove.Add(body);
                _numLeft--;
                continue;
            }

            _finished = false;
            var line = _lines[id];
            var tform = (Transform2D)PhysicsServer2D.BodyGetState(body, PhysicsServer2D.BodyState.Transform);
            var bodypos = tform.Origin - GlobalPosition;
            var vel = (Vector2)PhysicsServer2D.BodyGetState(body, PhysicsServer2D.BodyState.LinearVelocity);
            
            if (jitter && (Math.Abs(vel.X) > 10 || Math.Abs(vel.Y) > 10))
                bodypos += new Vector2(_rng.RandfRange((float)-JitterAmount, (float)JitterAmount),
                    _rng.RandfRange((float)-JitterAmount, (float)JitterAmount));
            
            if (quantize)
            {
                bodypos.X = (float)UMath.Stepify(bodypos.X, QuantizeAmount);
                bodypos.Y = (float)UMath.Stepify(bodypos.Y, QuantizeAmount);
            }
            
            var p1 = (line[^1]);
            var p2 = bodypos;
            
            System.Array.Copy(line, 2, line, 0, line.Length - 2);
            
            line[^2] = p1;
            line[^1] = p2;
            _lines[id] = line;
            
            DrawMultiline(line, Color, WIDTH, false);
        }

    }

    public override void _ExitTree()
    {
        Kill();
    }
}