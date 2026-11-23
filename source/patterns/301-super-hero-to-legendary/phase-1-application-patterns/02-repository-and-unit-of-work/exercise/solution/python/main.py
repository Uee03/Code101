class Database:
    def __init__(self):
        self.balances = {"a": 10, "b": 0}


class UnitOfWork:
    def __init__(self, db):
        self.db = db
        self.pending = {}

    def set_balance(self, name, value):
        self.pending[name] = value

    def commit(self):
        backup = dict(self.db.balances)
        try:
            for name in sorted(self.pending):
                if self.pending[name] < 0:
                    raise ValueError(f"negative balance for {name}")
                self.db.balances[name] = self.pending[name]
        except ValueError:
            self.db.balances = backup
            raise
        finally:
            self.pending = {}


db = Database()
uow = UnitOfWork(db)
uow.set_balance("a", 5)
uow.set_balance("b", 5)
uow.commit()
print(f"committed: a={db.balances['a']}, b={db.balances['b']}")

bad = UnitOfWork(db)
bad.set_balance("a", 1)
bad.set_balance("b", -1)
try:
    bad.commit()
except ValueError as error:
    print(f"rolled back: {error}")
print(f"unchanged: a={db.balances['a']}, b={db.balances['b']}")
