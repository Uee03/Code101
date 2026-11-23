namespace FacadeDemo;

public class Amplifier
{
    public void On(int volume) => Console.WriteLine($"Amplifier: on, volume {volume}");

    public void Off() => Console.WriteLine("Amplifier: off");
}

public class Projector
{
    public void On(string source) => Console.WriteLine($"Projector: on, input {source}");

    public void Off() => Console.WriteLine("Projector: off");
}

public class Player
{
    public void Play(string title) => Console.WriteLine($"Player: playing {title}");

    public void Stop() => Console.WriteLine("Player: stopped");
}

public class HomeTheater
{
    private readonly Amplifier _amplifier;
    private readonly Projector _projector;
    private readonly Player _player;

    public HomeTheater(Amplifier amplifier, Projector projector, Player player)
    {
        _amplifier = amplifier;
        _projector = projector;
        _player = player;
    }

    public void Watch(string title)
    {
        _amplifier.On(5);
        _projector.On("player");
        _player.Play(title);
    }

    public void End()
    {
        _player.Stop();
        _projector.Off();
        _amplifier.Off();
    }
}

public static class Demo
{
    public static void Run()
    {
        var theater = new HomeTheater(new Amplifier(), new Projector(), new Player());
        theater.Watch("Matrix");
        theater.End();
    }
}
