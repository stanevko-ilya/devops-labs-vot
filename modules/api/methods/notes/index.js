const Method = require('../_class');
const modules = require('../../../../modules');

class Notes extends Method {
    async getResponse() {
        return modules.db.req('note', 'find', [{}, null, { sort: { createdAt: -1 }, limit: 100 }]);
    }

    constructor(url, express) { super(__dirname, url, express) }
}

module.exports = Notes;
