const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getAllSettings = async (req, res) => {
  try {
    const settingsArr = await prisma.siteSetting.findMany();
    // Arrayni bitta obyektga aylantiramiz { key: value }
    const settings = {};
    settingsArr.forEach(s => {
      settings[s.key] = s.value;
    });
    
    res.json({ success: true, settings });
  } catch (error) {
    console.error('Get Settings Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateSetting = async (req, res) => {
  const { key, value } = req.body;
  try {
    const setting = await prisma.siteSetting.upsert({
      where: { key },
      update: { value },
      create: { key, value }
    });
    res.json({ success: true, setting });
  } catch (error) {
    console.error('Update Setting Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};
