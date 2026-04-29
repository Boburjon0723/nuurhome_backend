const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const productRoutes = require('./routes/productRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const colorRoutes = require('./routes/colorRoutes');
const orderRoutes = require('./routes/orderRoutes');
const uploadRoutes = require('./routes/uploadRoutes');
const financeRoutes = require('./routes/financeRoutes');
const statisticsRoutes = require('./routes/statisticsRoutes');
const excelImportRoutes = require('./routes/excelImportRoutes');
const employeeRoutes = require('./routes/employeeRoutes');
const warehouseRoutes = require('./routes/warehouseRoutes');
const messageRoutes = require('./routes/messageRoutes');
const albumRoutes = require('./routes/albumRoutes');

const app = express();
const PORT = 5000;

// Middleware
app.use(cors());
// Excel import / bulk order payloadlar kattaroq bo'lishi mumkin.
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('dev'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/colors', colorRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/finance', financeRoutes);
app.use('/api/statistics', statisticsRoutes);
app.use('/api/excel-import', excelImportRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/warehouse', warehouseRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/album', albumRoutes);

app.get('/', (req, res) => {
  res.json({ message: 'NuurHome API is running...' });
});

// Health check
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'up', timestamp: new Date() });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
