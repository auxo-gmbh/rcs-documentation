const {createSession} = require('./database');
const {databases, algorithms, queueSizes} = require('./constants');
const {
    extractAmountNodesByDB, extractAlgByDB, writeBarChartCsvFile, convertToRelativeTimestampMap,
    writeTimeChartCsvFile, writeBoxplotCsvFile
} = require("./utilities");

const BOXPLOT_QUERY = `
MATCH (source: Device)-[r:SENT_TO]->(target: Device) 
WHERE source <> target AND r.requestId IS NOT NULL
WITH r.requestId as reqID, count(r) as n
RETURN n as value
`
const getBoxplotDbResult = async (db, queueSize) => {
    const session = createSession(db);
    const queryResult = await session.run(BOXPLOT_QUERY, {queueSize});
    const result = queryResult.records.map(record => record.get(0))
    await session.close();
    return result;
}

const generateBoxplotData = async () => {
    for (const db of databases) {
        const alg = extractAlgByDB(db)
        const amountNodes = extractAmountNodesByDB(db);
        const dbResult = await getBoxplotDbResult(db);
        if (db.endsWith("-fail")) {
            writeBoxplotCsvFile(`data/messages_per_request_boxplot/${alg}-n${amountNodes}-boxplot-fail.csv`, dbResult);
            console.log(`Finished data/messages_per_request_boxplot/${alg}-n${amountNodes}-boxplot-fail.csv`)
        } else {
            writeBoxplotCsvFile(`data/messages_per_request_boxplot/${alg}-n${amountNodes}-boxplot.csv`, dbResult);
            console.log(`Finished data/messages_per_request_boxplot/${alg}-n${amountNodes}-boxplot.csv`)
        }
    }
}

const run = async () => {
    await generateBoxplotData();
}

run().catch(console.error);
