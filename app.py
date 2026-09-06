
import os
import streamlit as st

from huggingface_hub import InferenceClient

from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import (
    RunnableParallel,
    RunnablePassthrough,
    RunnableLambda
)
from langchain_core.output_parsers import StrOutputParser
from langchain_core.messages import AIMessage


# =========================================================
# PAGE CONFIG
# =========================================================

st.set_page_config(
    page_title="Aircraft Maintenance Supply Chain AI Assistant",
    page_icon="✈️",
    layout="wide"
)


# =========================================================
# TITLE
# =========================================================

st.title("✈️ Aircraft Maintenance Supply Chain AI Assistant")

st.write(
    "Ask questions about supplier performance, inventory risk, "
    "procurement performance, quality concerns, and supply chain priorities."
)


# =========================================================
# HUGGING FACE TOKEN
# =========================================================

token = os.environ.get("HUGGINGFACEHUB_API_TOKEN")

if not token:
    st.error("Hugging Face token not found.")
    st.stop()


# =========================================================
# EMBEDDINGS
# =========================================================

@st.cache_resource
def load_embeddings():

    return HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-MiniLM-L6-v2"
    )


embeddings = load_embeddings()


# =========================================================
# FAISS VECTOR STORE
# =========================================================

@st.cache_resource
def load_vector_store():

    return FAISS.load_local(
        "faiss_index",
        embeddings,
        allow_dangerous_deserialization=True
    )


vector_store = load_vector_store()


# =========================================================
# RETRIEVER
# =========================================================

retriever = vector_store.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 4}
)


# =========================================================
# PROMPT
# =========================================================

prompt = ChatPromptTemplate.from_template("""

You are an AI assistant for an Aircraft Maintenance Supply Chain Analytics system.

Answer the user's question using ONLY the context provided below.

Context:
{context}

Question:
{question}

Instructions:

- Provide practical and actionable recommendations when appropriate.
- Clearly distinguish observed facts from recommendations or inferences.
- Do not claim causation unless directly supported by the context.
- Do not make unsupported assumptions.
- Use specific supplier, part, site, quantity, cost, or risk values when relevant.
- Keep the response concise and focused.
- Provide exactly 3 key observations and 3 recommendations.
- Do not repeat the same information.
- If the context is insufficient, say:

"I don't have enough information in the provided data."

Structure:

### 1. Key Observations

1.
2.
3.

### 2. Recommendations

1.
2.
3.

Answer:

""")


# =========================================================
# FORMAT DOCUMENTS
# =========================================================

def formatted_doc(docs):

    return "\n\n".join(
        doc.page_content
        for doc in docs
    )


# =========================================================
# HUGGING FACE CLIENT
# =========================================================

client = InferenceClient(
    api_key=token,
    provider="novita"
)


# =========================================================
# LLM FUNCTION
# =========================================================

def call_llm(prompt_value):

    messages = []

    for message in prompt_value.to_messages():

        if message.type == "human":
            role = "user"

        elif message.type == "ai":
            role = "assistant"

        else:
            role = "system"

        messages.append({
            "role": role,
            "content": message.content
        })

    response = client.chat.completions.create(
        model="meta-llama/Llama-3.1-8B-Instruct",
        messages=messages,
        max_tokens=1000
    )

    return AIMessage(
        content=response.choices[0].message.content
    )


llm_runnable = RunnableLambda(call_llm)


# =========================================================
# RAG CHAIN
# =========================================================

parallel_chain = RunnableParallel({

    "context":
        retriever | RunnableLambda(formatted_doc),

    "question":
        RunnablePassthrough()

})


parser = StrOutputParser()


main_chain = (
    parallel_chain
    | prompt
    | llm_runnable
    | parser
)


# =========================================================
# CHAT MEMORY
# =========================================================

if "messages" not in st.session_state:

    st.session_state.messages = []


# =========================================================
# WELCOME MESSAGE
# =========================================================

if len(st.session_state.messages) == 0:

    with st.chat_message("assistant"):

        st.markdown(
            """
            👋 **Hello!**

            I'm your **Aircraft Maintenance Supply Chain AI Assistant**.

            I can help you with:

            - Supplier performance
            - Inventory risk
            - Procurement performance
            - Quality concerns
            - Supply chain priorities

            You can ask me questions about the project data.
            """
        )


# =========================================================
# DISPLAY CHAT HISTORY
# =========================================================

for message in st.session_state.messages:

    with st.chat_message(message["role"]):

        st.markdown(message["content"])


# =========================================================
# SUGGESTED QUESTIONS
# =========================================================

st.subheader("💡 Suggested Questions")

col1, col2, col3 = st.columns(3)


with col1:

    supplier_question = st.button(
        "Supplier Risk",
        use_container_width=True
    )


with col2:

    inventory_question = st.button(
        "Inventory Risk",
        use_container_width=True
    )


with col3:

    quality_question = st.button(
        "Quality Concerns",
        use_container_width=True
    )


# =========================================================
# CHAT INPUT
# =========================================================

user_question = st.chat_input(
    "Ask something about your supply chain..."
)


# =========================================================
# SUGGESTED QUESTION HANDLING
# =========================================================

if supplier_question:

    user_question = (
        "Which suppliers require closer monitoring and why?"
    )


elif inventory_question:

    user_question = (
        "What actions can reduce inventory risk in the supply chain?"
    )


elif quality_question:

    user_question = (
        "What are the major quality concerns and which suppliers should management investigate?"
    )


# =========================================================
# PROCESS QUESTION
# =========================================================

if user_question:

    # Save user message

    st.session_state.messages.append({

        "role": "user",

        "content": user_question

    })


    # Display user message

    with st.chat_message("user"):

        st.markdown(user_question)


    # Handle greetings

    greetings = [
        "hello",
        "hi",
        "hey",
        "hello there",
        "good morning",
        "good afternoon",
        "good evening"
    ]


    if user_question.strip().lower() in greetings:

        response = (
            "Hello! 👋 How can I help you with the "
            "Aircraft Maintenance Supply Chain Analytics?"
        )


    else:

        # Generate AI response

        with st.chat_message("assistant"):

            with st.spinner(
                "🔍 Analyzing supply chain data..."
            ):

                response = main_chain.invoke(
                    user_question
                )

            st.markdown(response)


    # Save AI response

    st.session_state.messages.append({

        "role": "assistant",

        "content": response

    })
