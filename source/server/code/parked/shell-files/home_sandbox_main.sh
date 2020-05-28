
TAR_FILE="${TMP_DIR}/cyber-dojo.tar"
TMP_DIR=$(mktemp -d /tmp/XXXXXX)

function send_tgz()
{
  local -r signal="${1}"
  truncate_file "${TMP_DIR}/stdout"
  truncate_file "${TMP_DIR}/stderr"
  tar -rf "${TAR_FILE}" -C "${TMP_DIR}" stdout stderr status
  text_filenames | tar -C / -rf ${TAR_FILE} --verbatim-files-from -T -
  gzip < "${TAR_FILE}"
}

function text_filenames()
{
  find ${SANDBOX_DIR} -type f -exec \
    bash -c "is_truncated_text_file {} && unrooted {}" \;
}

function is_truncated_text_file()
{
  local -r filename="${1}"
  local -r size=$(stat -c%s "${filename}")
  if is_text_file "${filename}" "${size}"; then
    truncate_file "${filename}" "${size}"
    true
  else
    false
  fi
}

function is_text_file()
{
  # grep -q is --quiet, we are generating text file names.
  # grep -v is --invert-match.
  local -r filename="${1}"
  local -r size="${2}"
  if file --mime-encoding ${filename} | grep -qv "${filename}:\\sbinary"; then
    true
  elif [ "${size}" -lt 2 ]; then
    # file incorrectly reports very small text files as binary.
    true
  else
    false
  fi
}

function truncate_file()
{
  # Beware; truncate can extend OR strink the size of a file.
  # The +1 is so Ruby can detect and lop off the final extra byte.
  local -r filename="${1}"
  local -r size="${2}"
  if [ "${size}" -gt ${MAX_FILE_SIZE} ]; then
    truncate --size ${MAX_FILE_SIZE+1} "${filename}"
  fi
}

function unrooted()
{
  # tar prefer relative pathnames so strip leading /
  local -r filename="${1}"
  echo "${filename:1}"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
trap "send_tgz EXIT" EXIT
trap "send_tgz TERM" SIGTERM
cd "${SANDBOX_DIR}"
bash ./cyber-dojo.sh  \
       1> "${TMP_DIR}/stdout" \
       2> "${TMP_DIR}/stderr"
echo $? > "${TMP_DIR}/status"