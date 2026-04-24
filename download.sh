#!/bin/bash
#SBATCH --account=pawsey1348
#SBATCH --job-name=bpa-download
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --time=44:00:00
#SBATCH --mem=8G
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

cd /scratch/pawsey1348/nstratmann/pauci/data/raw

# download.sh
# Bulk download tool for the Bioplatforms Australia Data Portal
#
# This UNIX shell script was automatically generated.
#


export CKAN_API_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJUd0VXeEZnSnZjMGxGN2QwOElWTEx2RHVCMHp4OFVHeGRhUVVvVUJMOGpudzRNMGVhUnAwdTFqRVBaRWljakRQUUo0dFloUkwyR0dWd1ZsdCIsImlhdCI6MTc3Njc0Njg3OX0.2SyOFdPhJENKQCGY7kxRJLFWXd_j1IQx816S3ssThMQ

BPA_AGENT="data.bioplatforms.com download.sh/1.3 nstratmann (Contact help@bioplatforms.com)"

OPTIONAL_DOWNLOAD=false
OPTSTRING=":ho"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    h)
      echo "usage: download.sh [-h] [-o]"
      echo
      echo $BPA_AGENT
      echo
      echo "Tool to download files from the Bioplatforms Australia Data Portal"
      echo
      echo " optional arguments:"
      echo " -h, --help      show this help message and exit"
      echo " -o, --optional  Download optional files"
      echo
      exit 1
      ;;
    o)
      echo "Will download optional files"
      OPTIONAL_DOWNLOAD=true
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

# Check for API tokens or keys

if [ x"$eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiItYXFQai1rLWFBMVcwNWVydy1zYkUyVVN2SXo1TE1PdXFYVVBvNW1NNE1nQ2I3MUFSbkhXT0JjYzZuUERyOUNYd2xzbTdLdFFTUFFRMWZfaiIsImlhdCI6MTc3Mzk3OTcwMX0.bJNXVVtFPTbi0lA83EC1_V41cPhoePBpf4DR3Gvi1Ag" = "x" ]; then
  if [ x"" = "$2203216e-d2d6-47c6-a08e-2333e3b46576" ]; then
    echo "Please set the CKAN_API_TOKEN environment variable."
    echo
    echo "You can create your API Token by browsing to:"
    echo "https://data.bioplatforms.com/user/nstratmann"
    echo
    echo "Go to the API Tokens tab, and generate your token."
    echo
    echo "The API token is a long string of letters and digits"
    echo
    echo "To set the environment variable in Linux/MacOS/Unix, use"
    echo "the following command before running download.sh"
    echo "substituting your API token as required:"
    echo
    echo "export CKAN_API_TOKEN=***********************************"
    echo
    echo "You can check if it has been set correctly with the command:"
    echo
    echo "printenv CKAN_API_TOKEN"
    if [ -t 0 ] ; then
       read -p "Press key to continue... (script will exit) " -n1 -s
    fi
    exit 1
  else
    echo "The API key of the format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    echo "is now obsolete, and should be replaced wih a freshly generated API Token. "
    echo "You can create your API Token by browsing to:"
    echo "https://data.bioplatforms.com/user/nstratmann"
    echo
    echo "Go to the API Tokens tab, and generate your token."
    echo
    echo "The API token is a long string of letters and digits"
    echo
    echo "To set the environment variable in Linux/MacOS/Unix, use"
    echo "the following command before running download.sh"
    echo "substituting your API token as required:"
    echo
    echo "export CKAN_API_TOKEN=***********************************"
    echo
    echo "You can check if it has been set correctly with the command:"
    echo
    echo "printenv CKAN_API_TOKEN"
     if [ -t 0 ] ; then
       read -p "Press key to continue... script will run using the KEY provided " -n1 -s
     fi
  fi
fi



# Check we are being run from a suitable location

if [ ! -f tmp/bpa_a6060ea9_20260319T0633_urls.txt ]; then
  echo "tmp/bpa_a6060ea9_20260319T0633_urls.txt not found"
  echo
  echo "Please change to the directory containing the download.sh script"
  exit 1
fi

# Check for required programs

if ! which curl >/dev/null 2>&1; then
  echo "`curl` is not installed. Please install it."
  echo
  echo "On MacOS, it can be installed via HomeBrew (https://brew.sh/)"
  echo "using the command `brew install curl`"
  exit 1
fi

if ! which md5sum >/dev/null 2>&1; then
  echo "`md5sum` is not installed. Please install it."
  echo
  echo "On MacOS, it can be installed via HomeBrew (https://brew.sh/)"
  echo "using the command `brew install md5sha1sum`"
  exit 1
fi


CURL=`which curl`

# if on MacOS, favour homebrew curl over system curl
case "$OSTYPE" in
  darwin*)
    HBCURL="/usr/local/opt/curl/bin/curl"
    if [ -f $HBCURL -a -x $HBCURL ] ; then
        echo "Using curl installed via homebrew"
        CURL="$HBCURL"
    fi
    ;;
  *)
    ;;
esac

# Check program versions

# 7.58 required for correct Authorization header support
CURL_VERSION_REQUIRED="7.58"
CURL_VERSION=$($CURL --version | head -1 | awk '{print $2}')

function max()
{
  local m="$1"
  for n in "$@"
  do
    [ "$n" -gt "$m" ] && m="$n"
  done
  echo "$m"
}

# from https://apple.stackexchange.com/a/261863
function compare_versions()
{
  local v1=( $(echo "$1" | tr '.' ' ') )
  local v2=( $(echo "$2" | tr '.' ' ') )
  
  local len="$(max "${#v1[*]}" "${#v2[*]}")"
  for ((i=0; i<len; i++))
  do
    [ "${v1[i]:-0}" -gt "${v2[i]:-0}" ] && return 1
    [ "${v1[i]:-0}" -lt "${v2[i]:-0}" ] && return 2
  done
  return 0
}

compare_versions $CURL_VERSION $CURL_VERSION_REQUIRED
if [ $? -eq 2 ]; then
  echo "Your 'curl' version is outdated."
  echo
  echo "Path was                   : $CURL"
  echo
  echo "Minimum version required is: $CURL_VERSION_REQUIRED"
  echo "Version available is       : $CURL_VERSION"
  exit 1
fi

# Output debug information in files

# Output files

function prepend()
{
while read line; do
  echo "${1}${line}";
done
}

function output_file()
{
if [ -f $1 ]; then
  echo $1
  echo
  cat $1 | prepend "  "
  echo
fi
}

output_file QUERY.txt
output_file MEMBERSHIPS.txt
output_file OPTIONAL.txt

# Remove old MD5 log file
if [ -f tmp/md5sum.log ]; then
  rm tmp/md5sum.log
fi

# Undertake download

function file_checks()
{
  local F
  for F in "$@"; do
     if [ ! -f $F ] || [ ! -r $F ]; then
        echo "Problem with file $F"
        return 1
     fi
  done
  return 0
}


function download_data()
{
  URLS=$1
  MD5=$2
  ANNOTATION=$3

  echo "Checking URLs and MD5s ($ANNOTATION)"
  if ! file_checks $URLS $MD5 ; then
    echo "File problems! First try to rerun this script, and if the problem persists, consult the documentation at https://usersupport.bioplatforms.com/programmatic_access.html."
    echo "If your issue is still unresolved, please email QUERY.txt, MEMBERSHIPS.txt files and output to help@bioplatforms.com for support"
    exit 99
  fi

  echo "Downloading data ($ANNOTATION)"
while read URL; do
  echo "Downloading: $URL"
  if [ x"$CKAN_API_TOKEN" != "x" ]; then
      $CURL -O -L -C - -A "$BPA_AGENT" -H "Authorization: $CKAN_API_TOKEN" "$URL"
  elif [ x"$CKAN_API_KEY" != "x" ]; then
      $CURL -O -L -C - -A "$BPA_AGENT" -H "Authorization: $CKAN_API_KEY" "$URL"
  fi  
  if [ $? -ne 0 ] ; then
     echo "Error downloading: $URL"
  fi
  done < $URLS

echo "Data download complete. Verifying checksums:"
  md5sum -c $MD5 2>&1 | tee -a tmp/md5sum.log
}


download_data tmp/bpa_a6060ea9_20260319T0633_urls.txt tmp/bpa_a6060ea9_20260319T0633_md5sum.txt main
if [ "$OPTIONAL_DOWNLOAD" = true ] ; then
  download_data tmp/bpa_a6060ea9_20260319T0633_urls_optional.txt tmp/bpa_a6060ea9_20260319T0633_md5sum_optional.txt optional
fi
