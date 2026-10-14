process.env.API_PORT = '18084';
process.env.DB_URL ||= 'mongodb://127.0.0.1:27017/testdb-test';
process.env.INSTANCE_ID = 'integration-test';

const modules = require('../../modules');

describe('Заметки хранятся в MongoDB', () => {
    beforeAll(async () => {
        await modules.logger.start();
        await modules.db.start();
        await modules.api.start();
    }, 30000);

    afterAll(async () => {
        await modules.api.stop();
        await modules.db.stop();
        await modules.logger.stop();
    }, 30000);

    it('создаёт запись и возвращает её при новом запросе', async () => {
        const text = `integration-${Date.now()}`;
        try {
            const created = await fetch('http://127.0.0.1:18084/api/notes/add', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text }),
            });
            expect(created.status).toBe(200);

            const response = await fetch('http://127.0.0.1:18084/api/notes');
            expect(response.status).toBe(200);
            expect(response.headers.get('X-Backend-Instance')).toBe('integration-test');
            const data = await response.json();
            expect(data.response.some(note => note.text === text)).toBe(true);
        } finally {
            await modules.db.models.note.deleteMany({ text });
        }
    });
});
