import after
import before

print("--- before: 2 channels ---")
old_notifiers = [
    before.EmailNotifier(),
    before.UrgentEmailNotifier(),
    before.SmsNotifier(),
    before.UrgentSmsNotifier(),
]
for notifier in old_notifiers:
    print(notifier.send("Server down"))

print("--- after: 3 channels ---")
channels = [after.EmailChannel(), after.SmsChannel(), after.SlackChannel()]
tones = [after.PlainTone(), after.UrgentTone()]
for channel in channels:
    for tone in tones:
        print(after.Notifier(channel, tone).send("Server down"))
