import after
import before

ITEMS = [("Notebook", 1200, 2), ("Pen", 150, 4)]

print("--- before ---")
database = []
old_invoice = before.Invoice(1, "ana@example.com", ITEMS)
print(old_invoice.to_text())
old_invoice.save(database)
old_invoice.send_email()
print(f"Stored invoices: {len(database)}")

print("--- after ---")
formatter = after.InvoiceTextFormatter()
store = after.InvoiceStore()
sender = after.EmailSender()
invoice = after.Invoice(1, "ana@example.com", ITEMS)
print(formatter.format(invoice))
store.save(invoice)
sender.send_invoice(invoice)
print(f"Stored invoices: {store.count()}")
