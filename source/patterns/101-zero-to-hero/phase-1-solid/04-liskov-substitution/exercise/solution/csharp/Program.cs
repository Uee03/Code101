SendReport(new EmailChannel(), "Report ready");
SendText(new SmsChannel(), "Report ready");

static void SendReport(IAttachmentChannel channel, string message)
{
    Console.WriteLine(channel.Send(message));
    Console.WriteLine(channel.SendAttachment(message, "report.pdf"));
}

static void SendText(IChannel channel, string message)
{
    Console.WriteLine(channel.Send(message));
}

interface IChannel
{
    string Send(string message);
}

interface IAttachmentChannel : IChannel
{
    string SendAttachment(string message, string filename);
}

class EmailChannel : IAttachmentChannel
{
    public string Send(string message)
    {
        return $"Email: {message}";
    }

    public string SendAttachment(string message, string filename)
    {
        return $"Email: {message} [{filename}]";
    }
}

class SmsChannel : IChannel
{
    public string Send(string message)
    {
        return $"SMS: {message}";
    }
}
