var AWS      = require('aws-sdk');  
var zlib     = require('zlib');
var topicARN = "arn:aws:sns:us-west-2:320464205386:logs2MozDef";

AWS.config.region = 'us-west-2';

exports.handler = function(event, context) { 
    console.log("\n\nLoading handler\n\n");  
    // Unpack Event: ES log line.
    var payload = new Buffer(event.awslogs.data, 'base64');
    zlib.gunzip(payload, function(e, result) {
        if (e) { 
            context.fail(e);
            console.log(e);
        } else {
            result = JSON.stringify(result.toString());
            var msg_id = context.awsRequestId;
            var syslog_msg = buildSyslogMessage(result, msg_id);
            console.log(syslog_msg);
            publishToSNS(syslog_msg);
            context.succeed();
        }
    });
};


const buildSyslogMessage = (logline, msg_id) => {
  var ts     = new Date().toISOString();
  var host   = "elasticsearch.aws.com";
  var app    = "lambda";
  var level  = "[info]";
  var log    = "\"message\":" + logline;
  
  var fields = [ts, host, app, level, msg_id, log];
  var syslog_msg = fields.join(" ") ;
  return syslog_msg;
}

const publishToSNS = (log) => {  
    console.log("Publishing event to SNS...");
    var sns = new AWS.SNS();

    sns.publish({
        Message: log,
        TopicArn: topicARN,
    }, function(err, data) {
        if (err) {
            console.log(err.stack);
            throw new Error("Cannot publish to SNS");
        }
    });
    console.log('Log published to SNS!');  
};

