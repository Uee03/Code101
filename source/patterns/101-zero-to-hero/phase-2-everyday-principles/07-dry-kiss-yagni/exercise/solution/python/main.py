def clean_name(name):
    return name.strip()


def email_greeting(name):
    return "Hello " + clean_name(name) + ", welcome!"


def sms_greeting(name):
    return "Hello " + clean_name(name) + "!"


def initials(name):
    letters = ""
    for part in name.split():
        letters += part[0].upper()
    return letters


print(email_greeting("  Ana Silva "))
print(sms_greeting("  Ana Silva "))
print(initials("  Ana Silva "))
