SendReport(new EmailChannel(), "Report ready");
SendReport(new SmsChannel(), "Report ready");

// TODO 1: split IChannel in two: IChannel (only Send) and IAttachmentChannel : IChannel (adds SendAttachment).
// TODO 2: EmailChannel implements IAttachmentChannel. SmsChannel implements only IChannel and loses SendAttachment.
// TODO 3: add SendText(IChannel channel, string message) that only prints channel.Send(message).
// TODO 4: change SendReport to take an IAttachmentChannel and make the last line of the program use SendText for SMS.
//         The program must no longer crash.

static void SendReport(IChannel channel, string message)
{
    Console.WriteLine(channel.Send(message));
    Console.WriteLine(channel.SendAttachment(message, "report.pdf"));
}

interface IChannel
{
    string Send(string message);

    string SendAttachment(string message, string filename);
}

class EmailChannel : IChannel
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

    public string SendAttachment(string message, string filename)
    {
        throw new NotSupportedException("SMS cannot carry attachments");
    }
}
