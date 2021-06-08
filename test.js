const fs = require('fs');
const path = require('path');

// https://stackoverflow.com/questions/2727167/how-do-you-get-a-list-of-the-names-of-all-files-present-in-a-directory-in-node-j

function walkSync(currentDirPath, callback) {
    fs.readdirSync(currentDirPath).forEach(function (name) {
        let filePath = path.join(currentDirPath, name);
        let stat = fs.statSync(filePath);
        if (stat.isFile()) {
            callback(filePath, stat);
        } else if (stat.isDirectory()) {
            walkSync(filePath, callback);
        }
    });
}

var scripts = []
var scenes = []

walkSync('.', function(filePath, stat) {
    if(filePath.endsWith('.gd'))
        scripts.push(filePath)
    else if(filePath.endsWith('.tscn'))
        scenes.push(filePath)
});

//console.log('SCRIPTS:\n', scripts.join('\n'))

var bigRegex = /export\(NodePath\) onready var (.*?) = get_node\(\1\)(?: #?as (\w*))?/g
var replacements = []
for(let scriptPath of scripts){
    var script = fs.readFileSync(scriptPath, 'utf8')
    script = script.replace(bigRegex, (m, name, type) => {
        return `export ${name}_path: NodePath`
    })    
}