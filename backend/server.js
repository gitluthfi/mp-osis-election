const express = require('express');
const multer  = require('multer');
const path    = require('path');
const fs      = require('fs');
const db      = require('./db');

const app  = express();
const PORT = 3000;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ─── Multer (photo upload) ────────────────────────────────────────────────────
// Map MIME type → ekstensi file yang aman
const mimeToExt = {
  'image/jpeg': '.jpg', 'image/jpg': '.jpg',
  'image/png':  '.png', 'image/gif': '.gif',
  'image/webp': '.webp',
};

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, path.join(__dirname, 'uploads/candidates')),
  filename: (req, file, cb) => {
    // Ambil ekstensi dari MIME type (lebih reliable dari originalname di Android)
    const extFromMime = mimeToExt[file.mimetype];
    const extFromName = path.extname(file.originalname || '').toLowerCase();
    const ext = extFromMime || extFromName || '.jpg';
    console.log(`[Upload] mimetype=${file.mimetype} originalname=${file.originalname} → ext=${ext}`);
    cb(null, Date.now() + ext);
  },
});
const upload = multer({
  storage,
  // Terima semua file image dan application/octet-stream (Android kadang kirim ini)
  fileFilter: (req, file, cb) => {
    const ok = file.mimetype.startsWith('image/') ||
               file.mimetype === 'application/octet-stream';
    console.log(`[Upload] fileFilter: mimetype=${file.mimetype} accepted=${ok}`);
    cb(null, ok);
  },
  limits: { fileSize: 10 * 1024 * 1024 },
});

// Wrapper agar error multer dikembalikan sebagai JSON, bukan HTML
function handleUpload(req, res, next) {
  upload.single('photo')(req, res, (err) => {
    if (err) {
      console.error('Multer error:', err.message);
      return res.status(400).json({ status: 'failed', message: `Upload error: ${err.message}` });
    }
    next();
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
function voterRow(row) {
  return {
    id_voter:       String(row.id_voter),
    code_voter:     row.code_voter,
    nik_voter:      row.nik_voter,
    password_voter: row.password_voter,
    islogin:        row.islogin,
    ischosen:       row.ischosen,
    role:           row.role,
  };
}

function photoUrl(req, filename) {
  if (!filename) return null;
  return `http://localhost:${PORT}/uploads/candidates/${filename}`;
}

function candidateRow(row, req) {
  return {
    id_candidate:    String(row.id_candidate),
    candidate_id:    row.candidate_id,
    candidate_name:  row.candidate_name,
    candidate_photo: row.candidate_photo ? photoUrl(req, row.candidate_photo) : null,
    description:     row.description,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH ENDPOINTS
// ═══════════════════════════════════════════════════════════════════════════════

// POST /api/Login
app.post('/api/Login', async (req, res) => {
  const { nik, password } = req.body;
  if (!nik || !password)
    return res.json({ status: 'failed', message: 'NIK and password required', data: null });

  try {
    const [rows] = await db.query(
      'SELECT * FROM voter WHERE nik_voter = ? AND password_voter = ?', [nik, password]
    );
    if (!rows.length)
      return res.json({ status: 'failed', message: 'Access denied', data: null });

    const voter = rows[0];

    // admin boleh multi-login, voter tidak
    if (voter.role === 'voter' && voter.islogin === '1')
      return res.json({ status: 'failed', message: 'You are already log in on other device', data: null });

    await db.query('UPDATE voter SET islogin = ? WHERE id_voter = ?', ['1', voter.id_voter]);
    voter.islogin = '1';

    return res.json({ status: 'success', message: 'Login successful', data: [voterRow(voter)] });
  } catch (err) {
    console.error(err);
    return res.json({ status: 'failed', message: 'Server error', data: null });
  }
});

// POST /api/Check
app.post('/api/Check', async (req, res) => {
  const { nik, password } = req.body;
  if (!nik || !password)
    return res.json({ status: 'failed', message: 'NIK and password required', data: null });

  try {
    const [rows] = await db.query(
      'SELECT * FROM voter WHERE nik_voter = ? AND password_voter = ?', [nik, password]
    );
    if (!rows.length)
      return res.json({ status: 'failed', message: 'Access denied', data: null });

    return res.json({ status: 'success', message: 'Check successful', data: [voterRow(rows[0])] });
  } catch (err) {
    console.error(err);
    return res.json({ status: 'failed', message: 'Server error', data: null });
  }
});

// POST /api/Vote
app.post('/api/Vote', async (req, res) => {
  const { nik, voter_id, candidate_id } = req.body;
  if (!nik || !voter_id || !candidate_id)
    return res.json({ status: 'failed', message: 'Missing required fields' });

  try {
    const [rows] = await db.query(
      'SELECT * FROM voter WHERE id_voter = ? AND nik_voter = ?', [voter_id, nik]
    );
    if (!rows.length)
      return res.json({ status: 'failed', message: 'Access denied' });

    if (rows[0].ischosen === '1')
      return res.json({ status: 'failed', message: 'User already choosing' });

    await db.query('UPDATE voter SET ischosen = ? WHERE id_voter = ?', ['1', rows[0].id_voter]);
    await db.query(
      'INSERT INTO vote_record (voter_id, candidate_id) VALUES (?, ?)',
      [rows[0].id_voter, candidate_id]
    );
    return res.json({ status: 'success', message: 'Vote recorded successfully' });
  } catch (err) {
    console.error(err);
    return res.json({ status: 'failed', message: 'Server error' });
  }
});

// POST /api/Logout
app.post('/api/Logout', async (req, res) => {
  const { nik, password } = req.body;
  if (!nik || !password)
    return res.json({ status: 'failed', message: 'NIK and password required' });

  try {
    const [rows] = await db.query(
      'SELECT * FROM voter WHERE nik_voter = ? AND password_voter = ?', [nik, password]
    );
    if (!rows.length)
      return res.json({ status: 'failed', message: 'Access denied' });

    await db.query('UPDATE voter SET islogin = ? WHERE id_voter = ?', ['0', rows[0].id_voter]);
    return res.json({ status: 'success', message: 'Logout successful' });
  } catch (err) {
    console.error(err);
    return res.json({ status: 'failed', message: 'Server error' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// CANDIDATE ENDPOINTS
// ═══════════════════════════════════════════════════════════════════════════════

// GET /api/Candidate
app.get('/api/Candidate', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM candidate ORDER BY CAST(candidate_id AS UNSIGNED)');
    return res.json({ status: 'success', data: rows.map(r => candidateRow(r, req)) });
  } catch (err) {
    console.error(err);
    return res.json({ status: 'failed', data: [] });
  }
});

// POST /api/Candidate/Add
app.post('/api/Candidate/Add', handleUpload, async (req, res) => {
  const { candidate_id, candidate_name, description } = req.body;
  if (!candidate_id || !candidate_name)
    return res.json({ status: 'failed', message: 'candidate_id and candidate_name required' });

  const filename = req.file ? req.file.filename : null;
  try {
    await db.query(
      'INSERT INTO candidate (candidate_id, candidate_name, candidate_photo, description) VALUES (?, ?, ?, ?)',
      [candidate_id, candidate_name, filename, description || null]
    );
    return res.json({ status: 'success', message: 'Candidate added' });
  } catch (err) {
    if (req.file) fs.unlinkSync(req.file.path);
    console.error(err);
    const msg = err.code === 'ER_DUP_ENTRY' ? 'Candidate ID already exists' : 'Server error';
    return res.json({ status: 'failed', message: msg });
  }
});

// POST /api/Candidate/Update/:id
app.post('/api/Candidate/Update/:id', handleUpload, async (req, res) => {
  const { id } = req.params;
  const { candidate_id, candidate_name, description } = req.body;
  if (!candidate_id || !candidate_name)
    return res.json({ status: 'failed', message: 'candidate_id and candidate_name required' });

  try {
    const [existing] = await db.query('SELECT * FROM candidate WHERE id_candidate = ?', [id]);
    if (!existing.length) return res.json({ status: 'failed', message: 'Candidate not found' });

    const oldFile = existing[0].candidate_photo;
    const newFile = req.file ? req.file.filename : oldFile;

    await db.query(
      'UPDATE candidate SET candidate_id=?, candidate_name=?, candidate_photo=?, description=? WHERE id_candidate=?',
      [candidate_id, candidate_name, newFile, description || null, id]
    );

    // hapus foto lama jika ada foto baru
    if (req.file && oldFile) {
      const oldPath = path.join(__dirname, 'uploads/candidates', oldFile);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    return res.json({ status: 'success', message: 'Candidate updated' });
  } catch (err) {
    if (req.file) fs.unlinkSync(req.file.path);
    console.error(err);
    return res.json({ status: 'failed', message: 'Server error' });
  }
});

// DELETE /api/Candidate/Delete/:id
app.delete('/api/Candidate/Delete/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await db.query('SELECT * FROM candidate WHERE id_candidate = ?', [id]);
    if (!rows.length) return res.json({ status: 'failed', message: 'Candidate not found' });

    await db.query('DELETE FROM candidate WHERE id_candidate = ?', [id]);

    if (rows[0].candidate_photo) {
      const filePath = path.join(__dirname, 'uploads/candidates', rows[0].candidate_photo);
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    }
    return res.json({ status: 'success', message: 'Candidate deleted' });
  } catch (err) {
    console.error(err);
    return res.json({ status: 'failed', message: 'Server error' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD ENDPOINT (admin only)
// ═══════════════════════════════════════════════════════════════════════════════

// GET /api/Dashboard
app.get('/api/Dashboard', async (req, res) => {
  try {
    const [[{ total }]]  = await db.query("SELECT COUNT(*) as total FROM voter WHERE role='voter'");
    const [[{ voted }]]  = await db.query("SELECT COUNT(*) as voted FROM voter WHERE role='voter' AND ischosen='1'");
    const [results]      = await db.query(`
      SELECT c.candidate_id, c.candidate_name, c.candidate_photo,
             COUNT(v.id) AS vote_count
      FROM candidate c
      LEFT JOIN vote_record v ON v.candidate_id = c.candidate_id
      GROUP BY c.id_candidate
      ORDER BY CAST(c.candidate_id AS UNSIGNED)
    `);

    return res.json({
      status: 'success',
      data: {
        total_voters:  total,
        total_voted:   voted,
        total_unvoted: total - voted,
        vote_results:  results.map(r => ({
          candidate_id:   r.candidate_id,
          candidate_name: r.candidate_name,
          candidate_photo: r.candidate_photo ? photoUrl(null, r.candidate_photo) : null,
          vote_count:     Number(r.vote_count),
        })),
      },
    });
  } catch (err) {
    console.error(err);
    return res.json({ status: 'failed', data: null });
  }
});

// ─── Global error handler — selalu kembalikan JSON, bukan HTML ────────────────
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err.message);
  res.status(500).json({ status: 'failed', message: err.message || 'Server error' });
});

app.listen(PORT, () => console.log(`Election API running on http://localhost:${PORT}/api/`));
