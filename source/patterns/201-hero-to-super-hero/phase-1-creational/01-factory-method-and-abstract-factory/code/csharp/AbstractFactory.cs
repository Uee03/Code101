namespace AbstractFactoryDemo;

public interface IButton
{
    string Render();
}

public interface ICheckbox
{
    string Render();
}

public class LightButton : IButton
{
    public string Render() => "light button";
}

public class LightCheckbox : ICheckbox
{
    public string Render() => "light checkbox";
}

public class DarkButton : IButton
{
    public string Render() => "dark button";
}

public class DarkCheckbox : ICheckbox
{
    public string Render() => "dark checkbox";
}

public interface IThemeFactory
{
    IButton CreateButton();
    ICheckbox CreateCheckbox();
}

public class LightTheme : IThemeFactory
{
    public IButton CreateButton() => new LightButton();
    public ICheckbox CreateCheckbox() => new LightCheckbox();
}

public class DarkTheme : IThemeFactory
{
    public IButton CreateButton() => new DarkButton();
    public ICheckbox CreateCheckbox() => new DarkCheckbox();
}

public static class Demo
{
    public static string RenderForm(IThemeFactory theme)
    {
        IButton button = theme.CreateButton();
        ICheckbox checkbox = theme.CreateCheckbox();
        return $"{button.Render()} + {checkbox.Render()}";
    }

    public static void Run()
    {
        var themes = new (string Name, IThemeFactory Theme)[]
        {
            ("light", new LightTheme()),
            ("dark", new DarkTheme()),
        };
        foreach (var (name, theme) in themes)
        {
            Console.WriteLine($"{name}: {RenderForm(theme)}");
        }
    }
}
