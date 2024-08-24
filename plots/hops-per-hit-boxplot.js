const {createSession} = require('./database');
const {databases, algorithms, queueSizes} = require('./constants');
const {
    extractAmountNodesByDB, extractAlgByDB, writeBarChartCsvFile, convertToRelativeTimestampMap,
    writeTimeChartCsvFile, writeBoxplotCsvFile
} = require("./utilities");

const BOXPLOT_QUERY = `
MATCH (source:Device)-[s:SENT_TO]->(target:Device)
WHERE s.requestId IS NOT NULL AND source<>target
WITH s.requestId as reqID, collect(s) as requests
WHERE any(request in requests WHERE request.details="RESPONSE")
WITH reqID, requests
UNWIND requests as request
WITH reqID, max(size(request.path)) as pathSize
RETURN pathSize as value
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
            writeBoxplotCsvFile(`data/hops_per_hit_boxplot/${alg}-n${amountNodes}-boxplot-fail.csv`, dbResult);
            console.log(`Finished data/hops_per_hit_boxplot/${alg}-n${amountNodes}-boxplot-fail.csv`)
        } else {
            writeBoxplotCsvFile(`data/hops_per_hit_boxplot/${alg}-n${amountNodes}-boxplot.csv`, dbResult);
            console.log(`Finished data/hops_per_hit_boxplot/${alg}-n${amountNodes}-boxplot.csv`)
        }
    }
}

const run = async () => {
    await generateBoxplotData();
}

run().catch(console.error);
