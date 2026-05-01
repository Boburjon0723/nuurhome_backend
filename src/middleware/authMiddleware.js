const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  const token = req.header('Authorization')?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Avtorizatsiyadan o\'tilmagan, token topilmadi' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key');
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Token noto\'g\'ri yoki muddati o\'tgan' });
  }
};

const checkRole = (roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Sizda ushbu amalga ruxsat yo\'q' });
    }
    next();
  };
};

const adminMiddleware = (req, res, next) => {
  if (req.user.role?.toLowerCase() !== 'admin') {
    return res.status(403).json({ message: 'Faqat adminlar uchun ruxsat berilgan' });
  }
  next();
};

module.exports = { authMiddleware, checkRole, adminMiddleware };
