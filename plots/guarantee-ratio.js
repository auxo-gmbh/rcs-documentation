const {algorithms, databases} = require("./constants");
const {
    writeBarChartCsvFile, extractAmountNodesByDB,
    convertToRelativeTimestampMap,
    extractAlgByDB,
    writeTimeChartCsvFile
} = require("./utilities");
const {createSession} = require("./database");

const BAR_QUERY = `
MATCH (:Device)-[r:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WITH count(distinct r.requestId) as total
MATCH (:Device)-[response:SENT_TO {details: 'RESPONSE'}]->(:Device)-[offloaded:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE offloaded.requestId = response.requestId
WITH total, count(DISTINCT response.requestId) as hits
RETURN (hits * 1.0 / total * 1.0) * 100 as value
`

const TIME_QUERY = `
MATCH (:Device)-[res:SENT_TO {details: 'RESPONSE'}]->(:Device)-[req:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE res.requestId=req.requestId
WITH min(res.sentAt) as minTime
MATCH (:Device)-[res:SENT_TO {details: 'RESPONSE'}]->(:Device)-[req:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE res.requestId=req.requestId
WITH minTime, res.requestId as resID, res.sentAt as timestamp
OPTIONAL MATCH (:Device)-[r:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE r.sentAt<=timestamp
WITH minTime, timestamp, count(distinct r.requestId) as total
MATCH (:Device)-[res:SENT_TO {details: 'RESPONSE'}]->(:Device)-[req:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE res.requestId=req.requestId AND res.sentAt<=timestamp
WITH minTime, timestamp, total, count(distinct res.requestId) as hits
RETURN (timestamp-minTime)/60000.0 as time , (hits * 1.0 / total * 1.0) * 100 as value
ORDER BY time
`

const getBarChartDbResult = async (alg, isFailureRun) => {
    const result = {};
    const filteredDbs =
        databases
            .filter(db => isFailureRun ? db.endsWith("-fail") : !db.endsWith("-fail"))
            .filter(db => db.startsWith(alg));
    for (const db of filteredDbs) {
        const amountNodes = extractAmountNodesByDB(db);
        const session = createSession(db);
        const queryResult = await session.run(BAR_QUERY);
        result[amountNodes] = queryResult.records[0].get(0);
        await session.close();
    }
    return result;
};

const generateBarChartData = async () => {
    for (const alg of algorithms) {
        const dbResult = await getBarChartDbResult(alg, false);
        writeBarChartCsvFile(`data/guarantee_ratio/${alg}.csv`, dbResult);

        const dbFailResult = await getBarChartDbResult(alg, true);
        writeBarChartCsvFile(`data/guarantee_ratio/${alg}-fail.csv`, dbFailResult);
    }
};

const getTimeChartDbResult = async (db) => {
    const session = createSession(db);
    const queryResult = await session.run(TIME_QUERY);
    const result = queryResult.records
        .map(record => {
            const timestamp = record.get(0).toString();
            const averageServiceTime = record.get(1);
            return {timestamp, averageServiceTime};
        })
        .reduce((map, record) => {
            map[record.timestamp] = record.averageServiceTime;
            return map;
        }, {})
    await session.close();
    return result;
}

const generateAverageTimeChartData = async (db, dbResult) => {
    const session = createSession(db);
    const averageQueryResult = await session.run(BAR_QUERY);
    const averageValue = averageQueryResult.records[0].get(0);
    await session.close();
    const map = {}
    Object
        .entries(dbResult)
        .map(([timestamp, _]) => map[timestamp] = averageValue);
    return map;
};

const generateTimeChartData = async () => {
    for (const db of databases) {
        const alg = extractAlgByDB(db);
        const amountNodes = extractAmountNodesByDB(db);
        const dbResult = await getTimeChartDbResult(db);
        const averageDbResult = await generateAverageTimeChartData(db, dbResult);
        if (db.endsWith("-fail")) {
            writeTimeChartCsvFile(`data/guarantee_ratio/${alg}-n${amountNodes}-time-fail.csv`, dbResult);
            writeTimeChartCsvFile(`data/guarantee_ratio/${alg}-n${amountNodes}-time-fail-average.csv`, averageDbResult);
        } else {
            writeTimeChartCsvFile(`data/guarantee_ratio/${alg}-n${amountNodes}-time.csv`, dbResult);
            writeTimeChartCsvFile(`data/guarantee_ratio/${alg}-n${amountNodes}-time-average.csv`, averageDbResult);
        }
        console.log(`Finished with ${db}`)
    }
};

const run = async () => {
    await generateBarChartData();
    await generateTimeChartData();
    console.log('FINISHED')
};

run().then().catch(console.error)
