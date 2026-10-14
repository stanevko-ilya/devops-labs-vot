const Method = require('../../_class');
const modules = require('../../../../../modules');

class AddNote extends Method {
    async getResponse(req) {
        const text = req.container_data.text.trim();
        if (!text || text.length > 280) return { error_code: 1, status: 400 };
        return modules.db.req('note', 'create', [{ text }]);
    }

    getTest() {
        return {
            request: { params: { text: '   ' } },
            expect: { status: 400, body: error => error.code === 1 }
        };
    }

    constructor(url, express) { super(__dirname, url, express) }
}

module.exports = AddNote;
