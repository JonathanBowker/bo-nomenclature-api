const STORAGE_KEY = "bo-nomenclature-graphql-explorer";

const examples = {
  domains: {
    title: "Domains collection",
    query: `query GetDomains {
  domainsCollection(first: 10, orderBy: [{created_at: AscNullsLast}]) {
    edges {
      node {
        id
        name
        slug
        domain_type
        status
        parent_id
      }
    }
  }
}`,
    variables: {}
  },
  hotelTerm: {
    title: "Imported hotel term",
    query: `query GetDisneyHotelTerm {
  termsCollection(
    first: 1
    filter: {id: {eq: "12b8e98b-7593-5b51-b8cc-3c9084cbcb32"}}
  ) {
    edges {
      node {
        id
        canonical_text
        category
        source_reference
        variantsCollection(first: 10) {
          edges {
            node {
              variant_text
              variant_type
              locale_code
            }
          }
        }
        approvalsCollection(first: 10) {
          edges {
            node {
              destination_code
              status
              comment
            }
          }
        }
      }
    }
  }
}`,
    variables: {}
  },
  wdwTerms: {
    title: "Walt Disney World sample terms",
    query: `query GetWDWSampleTerms {
  termsCollection(
    first: 8
    filter: {domain_id: {eq: "72000000-0000-0000-0000-000000000004"}}
    orderBy: [{canonical_text: AscNullsLast}]
  ) {
    edges {
      node {
        id
        canonical_text
        category
      }
    }
  }
}`,
    variables: {}
  },
  auditTrail: {
    title: "Audit trail",
    query: `query GetAuditEntriesForHotelTerm {
  audit_entriesCollection(
    first: 10
    filter: {entity_id: {eq: "12b8e98b-7593-5b51-b8cc-3c9084cbcb32"}}
    orderBy: [{occurred_at: DescNullsLast}]
  ) {
    edges {
      node {
        id
        entity_type
        entity_id
        action
        occurred_at
      }
    }
  }
}`,
    variables: {}
  },
  approvalState: {
    title: "Approval state function",
    query: `query GetApprovalState {
  term_active_approval_state(
    input_term_id: "12b8e98b-7593-5b51-b8cc-3c9084cbcb32"
    input_destination_code: "disneyland_paris"
  )
}`,
    variables: {}
  },
  introspection: {
    title: "Schema introspection",
    query: `query IntrospectionOverview {
  __schema {
    queryType {
      fields {
        name
      }
    }
    mutationType {
      fields {
        name
      }
    }
  }
}`,
    variables: {}
  }
};

const endpointInput = document.getElementById("endpoint");
const apiKeyInput = document.getElementById("apiKey");
const bearerTokenInput = document.getElementById("bearerToken");
const queryEditor = document.getElementById("queryEditor");
const variablesEditor = document.getElementById("variablesEditor");
const responseViewer = document.getElementById("responseViewer");
const requestViewer = document.getElementById("requestViewer");
const statusBadge = document.getElementById("statusBadge");
const titleNode = document.getElementById("activeExampleTitle");

const exampleButtons = [...document.querySelectorAll(".example-item")];

let activeExample = "domains";

function setStatus(kind, label) {
  statusBadge.className = `status-badge ${kind}`;
  statusBadge.textContent = label;
}

function renderRequestPreview() {
  let variables = {};
  try {
    variables = JSON.parse(variablesEditor.value || "{}");
  } catch {
    variables = "__invalid_json__";
  }

  requestViewer.textContent = JSON.stringify(
    {
      query: queryEditor.value,
      variables
    },
    null,
    2
  );
}

function applyExample(name) {
  const example = examples[name];
  if (!example) return;

  activeExample = name;
  titleNode.textContent = example.title;
  queryEditor.value = example.query;
  variablesEditor.value = JSON.stringify(example.variables, null, 2);
  renderRequestPreview();

  exampleButtons.forEach((button) => {
    button.classList.toggle("is-active", button.dataset.example === name);
  });
}

function saveConnection() {
  const payload = {
    endpoint: endpointInput.value,
    apiKey: apiKeyInput.value,
    bearerToken: bearerTokenInput.value
  };

  localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  setStatus("success", "Saved");
  setTimeout(() => setStatus("idle", "Idle"), 1000);
}

function loadConnection() {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return;
  try {
    const payload = JSON.parse(raw);
    endpointInput.value = payload.endpoint || endpointInput.value;
    apiKeyInput.value = payload.apiKey || "";
    bearerTokenInput.value = payload.bearerToken || "";
  } catch {
    localStorage.removeItem(STORAGE_KEY);
  }
}

async function runQuery() {
  let variables = {};
  try {
    variables = JSON.parse(variablesEditor.value || "{}");
  } catch (error) {
    setStatus("error", "Bad JSON");
    responseViewer.textContent = `Variables must be valid JSON.\n\n${String(error)}`;
    return;
  }

  const apiKey = apiKeyInput.value.trim();
  const bearerToken = (bearerTokenInput.value.trim() || apiKey).trim();

  if (!endpointInput.value.trim() || !apiKey) {
    setStatus("error", "Missing Auth");
    responseViewer.textContent = "Endpoint and API key are required.";
    return;
  }

  const payload = {
    query: queryEditor.value,
    variables
  };

  renderRequestPreview();
  setStatus("running", "Running");
  responseViewer.textContent = "Request in flight…";

  try {
    const response = await fetch(endpointInput.value.trim(), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: apiKey,
        Authorization: `Bearer ${bearerToken}`
      },
      body: JSON.stringify(payload)
    });

    const text = await response.text();
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }

    responseViewer.textContent = typeof body === "string" ? body : JSON.stringify(body, null, 2);
    setStatus(response.ok ? "success" : "error", response.ok ? "Success" : `HTTP ${response.status}`);
  } catch (error) {
    responseViewer.textContent = String(error);
    setStatus("error", "Network");
  }
}

function copyText(value) {
  navigator.clipboard.writeText(value).catch(() => {});
}

document.getElementById("runQuery").addEventListener("click", runQuery);
document.getElementById("saveConnection").addEventListener("click", saveConnection);
document.getElementById("copyQuery").addEventListener("click", () => copyText(queryEditor.value));
document.getElementById("copyResponse").addEventListener("click", () => copyText(responseViewer.textContent));
document.getElementById("formatVariables").addEventListener("click", () => {
  try {
    const value = JSON.parse(variablesEditor.value || "{}");
    variablesEditor.value = JSON.stringify(value, null, 2);
    renderRequestPreview();
  } catch (error) {
    setStatus("error", "Bad JSON");
    responseViewer.textContent = `Variables must be valid JSON.\n\n${String(error)}`;
  }
});
document.getElementById("loadIntrospection").addEventListener("click", () => applyExample("introspection"));

queryEditor.addEventListener("input", renderRequestPreview);
variablesEditor.addEventListener("input", renderRequestPreview);

exampleButtons.forEach((button) => {
  button.addEventListener("click", () => applyExample(button.dataset.example));
});

loadConnection();
applyExample(activeExample);
setStatus("idle", "Idle");
