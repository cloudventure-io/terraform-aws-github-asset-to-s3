const {
  S3Client,
  HeadObjectCommand,
  PutObjectCommand,
  NotFound,
} = require("@aws-sdk/client-s3");

const s3 = new S3Client({});

const { fetch, Response } = require("fetch");
const fs = require("fs");
const path = require("path");

const packageJSON = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../package.json"))
);

/**
 *
 * @param {string} url
 * @returns {Promise<Response>}
 */
const fetchFollowRedirects = async (url, headers = {}) => {
  const res = await fetch(url, { headers });
  if (res.status == 302 && res.headers.location) {
    return fetchFollowRedirects(res.headers.location);
  }
  if (res.status !== 200) {
    throw new Error(
      `received unexpected status code ${res.status} when requesting ${url}`
    );
  }
  return res;
};

/**
 * @typedef LambdaEvent
 * @property {string} repository
 * @property {string} tag
 * @property {string} assetName
 * @property {string} [token]
 * @property {string} bucket
 * @property {string} key
 */

/**
 * @typedef LambdaResponse
 * @property {string} bucket
 * @property {string} key
 */

/**
 *
 * @param {LambdaEvent} event
 * @returns {LambdaResponse}
 */
exports.handler = async ({
  repository,
  tag,
  assetName,
  token,
  bucket,
  key,
}) => {
  let exists = false;
  try {
    await s3.send(
      new HeadObjectCommand({
        Bucket: bucket,
        Key: key,
      })
    );
    exists = true;
  } catch (ex) {
    if (!(ex instanceof NotFound)) {
        throw ex;
    }
  }

  if (!exists) {
    const headers = {
      Authorization: token ? `Token ${token}` : undefined,
      "User-Agent": `${packageJSON.name}/${packageJSON.version}`,
    };

    const assetsResponse = await fetch(
      `https://api.github.com/repos/${repository}/releases/tags/${tag}`,
      {
        headers: {
          ...headers,
          Accept: "application/json",
        },
      }
    );

    if (assetsResponse.status !== 200) {
      throw new Error(
        `received unexpected status code ${assetsResponse.status} when requesting https://api.github.com/repos/${repository}/releases/tags/${tag}`
      );
    }

    const { assets } = await assetsResponse.json();
    const asset = assets.find((asset) => asset.name == assetName);

    if (!asset) {
      throw new Error(`asset ${assetName} not found`);
    }

    const response = await fetchFollowRedirects(asset.url, {
      ...headers,
      Accept: "application/octet-stream",
    });

    await s3.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        Body: await response.blob(),
      })
    );
  }

  return {
    bucket,
    key,
  };
};
