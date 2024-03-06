#!/bin/bash
#=================================================
# name:   rm-print-url.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   29/11/2020
#=================================================
# npm install -g readability-cli
url=$1
dest=${2:-$HOME/Print.pdf}
tmpdir=$(mktemp -d)
filename=${3:-$(date +%Y-%m-%d_%H-%M_%s)}
cd $tmpdir
# echo $tmpdir

cat > $filename.begin <<STYLE
<head>
    <meta charset="UTF-8">
    <style>
        h1 {
            text-align: center;
        }
        img {
            display: none;
        }
        body {
            font-size: 1.2rem;
            margin-left: 60px;
            margin-right: 60px;
        }
        blockquote {
            margin: 16px 0;
            padding-left: 10px;
            border-left: 10px solid lightgray;
        }
        pre {
            white-space: normal;
        }
    </style>
</head>
<body>
STYLE
cat > $filename.end <<STYLE
</body>
STYLE

readable --low-confidence force "$url" > $filename.content
if [[ $? != 0 ]]; then
    echo "Can not convert to readable format :("
    exit 1
fi

cat $filename.begin $filename.content $filename.end > $filename.html

# google-chrome-stable --headless --disable-gpu --print-to-pdf $filename.html
wkhtmltopdf $filename.html $filename.pdf
if [[ $? != 0 ]]; then
    echo "Can not convert to pdf :("
    exit 2
fi

# mv *.pdf $filename.pdf

# rmapi put $filename.pdf $dest 1>&2
cp $filename.pdf $dest

# if [[ $? != 0 ]]; then
#     echo "Can not send to reMarkable Cloud :("
#     exit 2
# fi

# echo "File $filename sent to reMarkable $dest folder :)"

