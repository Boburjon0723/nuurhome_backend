-- Xarajat yozuvlarida expense_type_id ixtiyoriy (diagramma: barg bo'limda to'g'ridan-to'g'ri xarajat)
ALTER TABLE department_expense_entries
    ALTER COLUMN expense_type_id DROP NOT NULL;
