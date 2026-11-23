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
        # TODO 1: copy the current balances first (the backup).
        # TODO 2: apply every pending value in sorted name order; before assigning a value,
        #         raise ValueError(f"negative balance for {name}") if it is below zero.
        # TODO 3: if an error happens, put the backup back (rollback) and raise again.
        # TODO 4: always clear self.pending at the end.
        raise NotImplementedError


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
