const { createClient } = require('@supabase/supabase-js');

function getSupabaseClient() {
    const url = String(process.env.NUUR_SOURCE_SUPABASE_URL || process.env.SUPABASE_URL || '').trim();
    const key = String(process.env.NUUR_SOURCE_SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY || '').trim();
    if (!url || !key) return null;
    return createClient(url, key);
}

exports.uploadMultiple = async (req, res) => {
    try {
        const supabase = getSupabaseClient();
        if (!supabase) {
            return res.status(500).json({
                message: 'SUPABASE_URL va SUPABASE_ANON_KEY backend .env faylida yoqilmagan'
            });
        }
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ message: 'Fayllar yuklanmadi' });
        }

        const urls = [];
        for (const file of req.files) {
            const fileName = `${Date.now()}-${file.originalname}`;
            const { data, error } = await supabase.storage
                .from('products') // Make sure this bucket exists and is public
                .upload(fileName, file.buffer, {
                    contentType: file.mimetype,
                    upsert: true
                });

            if (error) throw error;

            const { data: { publicUrl } } = supabase.storage
                .from('products')
                .getPublicUrl(fileName);

            urls.push(publicUrl);
        }

        res.json({ urls });
    } catch (error) {
        console.error('Upload Error:', error);
        res.status(500).json({ message: error.message });
    }
};
