const {createSession} = require('./database');
const {databases, algorithms, queueSizes} = require('./constants');
const {
    extractAmountNodesByDB, extractAlgByDB, writeBarChartCsvFile, convertToRelativeTimestampMap,
    writeTimeChartCsvFile, writeBoxplotCsvFile
} = require("./utilities");

const BOXPLOT_QUERY = `
MATCH (:Device)-[response:SENT_TO {details: 'RESPONSE'}]->(:Device)-[offloaded:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE offloaded.requestId = response.requestId
RETURN (response.sentAt-offloaded.sentAt)/1000.0 as value
`
const GOSSIPS_BOXPLOT_QUERY = `
MATCH (:Device)-[response:SENT_TO {details: 'RESPONSE'}]->(:Device)-[offloaded:SENT_TO {details: 'GOSSIPS_DISCOVERY_REQUEST'}]->(:Device)
WHERE offloaded.requestId = response.requestId AND response.path=[]
WITH offloaded.requestId as reqID, min(offloaded.sentAt) as reqTime, max(response.sentAt) as resTime
RETURN (resTime-reqTime)/1000.0  as value
`

const getBoxplotDbResult = async (alg, db) => {
    const session = createSession(db);
    let query = ""
    if (alg !== "gossips") {
        query = BOXPLOT_QUERY
    } else {
        query = GOSSIPS_BOXPLOT_QUERY
    }
    const queryResult = await session.run(query);
    const result = queryResult.records.map(record => record.get(0))
    await session.close();
    return result;
}

const generateBoxplotData = async () => {
    for (const db of databases) {
        const alg = extractAlgByDB(db)
        const amountNodes = extractAmountNodesByDB(db);
        const dbResult = await getBoxplotDbResult(alg, db);
        if (db.endsWith("-fail")) {
            writeBoxplotCsvFile(`data/service_time_boxplot/${alg}-n${amountNodes}-boxplot-fail.csv`, dbResult);
            console.log(`Finished data/service_time_boxplot/${alg}-n${amountNodes}-boxplot-fail.csv`)
        } else {
            writeBoxplotCsvFile(`data/service_time_boxplot/${alg}-n${amountNodes}-boxplot.csv`, dbResult);
            console.log(`Finished data/service_time_boxplot/${alg}-n${amountNodes}-boxplot.csv`)
        }
    }
}

const run = async () => {
    await generateBoxplotData();
}

run().catch(console.error);
