def email_greeting(name):
    return "Hello " + name.strip() + ", welcome!"


def sms_greeting(name):
    return "Hello " + name.strip() + "!"


def greeting_as_xml(name):
    return "<greeting>" + name.strip() + "</greeting>"


def initials(name):
    return "".join(map(lambda part: part[0].upper(), filter(None, name.strip().split(" "))))


# TODO 1 (DRY): the cleaning step name.strip() is repeated. Move it into a function clean_name(name)
#               and call it from the greetings.
# TODO 2 (YAGNI): delete the function nobody calls.
# TODO 3 (KISS): rewrite initials with a plain for loop over name.split(). The output must not change.

print(email_greeting("  Ana Silva "))
print(sms_greeting("  Ana Silva "))
print(initials("  Ana Silva "))
