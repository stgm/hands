import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Drives the standalone student widget: subscribes to WidgetChannel for live
// updates (which also records "widget open" presence), and submits the widget's
// forms over fetch so cable-pushed HTML (whose embedded CSRF token isn't valid
// for this session) still works — the page's CSRF meta token is used instead.
export default class extends Controller {
    static values = { domain: String, source: String }

    connect() {
        this.generation = (this.generation || 0) + 1
        this.subscription = consumer.subscriptions.create(
            { channel: "WidgetChannel", domain: this.domainValue, source_label: this.sourceValue },
            { received: (data) => { if (data.html) this.swap(data.html) } }
        )
        this.heartbeat = setInterval(() => this.subscription.perform("appear"), 30000)
        this.bindForms()
        this.setupWaitingGif()
    }

    disconnect() {
        clearInterval(this.heartbeat)
        if (this.subscription) this.subscription.unsubscribe()
        // Revoking without also dropping the cached promise would leave a
        // resolved-to-a-dead-URL promise behind: Stimulus reuses this instance
        // when the element is re-connected, and setupWaitingGif() would then
        // assign the revoked blob URL to the fresh <img>. Always clear both.
        if (this.waitingGifObjectUrl) { URL.revokeObjectURL(this.waitingGifObjectUrl); this.waitingGifObjectUrl = null }
        this.waitingGifPromise = null
        this.generation = (this.generation || 0) + 1
    }

    swap(html) {
        this.element.innerHTML = html
        this.bindForms()
        this.setupWaitingGif()
        const field = this.element.querySelector("[autofocus], textarea, input[type=text]")
        if (field) field.focus()
    }

    bindForms() {
        this.element.querySelectorAll("form").forEach((form) => {
            form.addEventListener("submit", (e) => this.submit(e, form), { once: true })
        })
    }

    // Random waiting GIF, remembered across updates (as course-site did). The
    // gif is stored in the repo XOR-obfuscated so it isn't visible as-is on
    // GitHub; decode it here into a Blob and show that instead.
    //
    // swap() can fire twice in quick succession (a cable push racing the
    // fetch response from submit()), each replacing this.element's innerHTML
    // and thus the #waiting-gif node. Decoding is shared across calls via
    // waitingGifPromise, and the resolved URL is applied to whichever
    // #waiting-gif element is current *when it resolves* rather than one
    // captured up front, so a stale/detached element from an earlier swap()
    // never ends up as the one holding the blob src.
    setupWaitingGif() {
        const img = this.element.querySelector("#waiting-gif")
        if (!img) return
        img.onerror = () => { img.style.display = "none" }

        if (this.waitingGifObjectUrl) { img.src = this.waitingGifObjectUrl; return }

        if (!this.waitingGifPromise) {
            this.waitingGifPromise = this.decodeWaitingGif(img).catch((e) => { this.waitingGifPromise = null; throw e })
        }

        const generation = this.generation
        this.waitingGifPromise.then((url) => {
            // A disconnect while the decode was in flight bumps generation on
            // the next connect(); that run has its own promise, so drop this
            // url rather than leaking it or showing it on a stale element.
            if (generation !== this.generation) { URL.revokeObjectURL(url); return }
            this.waitingGifObjectUrl = url
            const currentImg = this.element.querySelector("#waiting-gif")
            if (currentImg) currentImg.src = url
        }).catch(() => {
            const currentImg = this.element.querySelector("#waiting-gif")
            if (currentImg) currentImg.style.display = "none"
        })
    }

    async decodeWaitingGif(img) {
        const urls = JSON.parse(img.dataset.waitingGifUrls || "[]")
        if (urls.length === 0) throw new Error("no waiting gif urls")

        let chosen = localStorage["hands-waiting-gif"]
        if (!chosen || !urls.includes(chosen)) {
            chosen = urls[Math.floor(Math.random() * urls.length)]
            localStorage["hands-waiting-gif"] = chosen
        }

        const key = img.dataset.waitingGifKey.match(/../g).map((h) => parseInt(h, 16))
        const res = await fetch(chosen)
        if (!res.ok) throw new Error("fetch failed")
        const bytes = new Uint8Array(await res.arrayBuffer())
        for (let i = 0; i < bytes.length; i++) bytes[i] ^= key[i % key.length]
        return URL.createObjectURL(new Blob([bytes], { type: "image/gif" }))
    }

    async submit(event, form) {
        event.preventDefault()
        this.showLoading(form)
        const data = new FormData(form)
        const method = (data.get("_method") || form.getAttribute("method") || "post").toLowerCase()
        data.delete("_method")

        const httpMethod = method === "delete" ? "DELETE" : (method === "patch" ? "PATCH" : "POST")
        const options = {
            method: httpMethod,
            headers: { "X-CSRF-Token": this.csrfToken(), "X-Widget-Fragment": "1" },
            credentials: "same-origin"
        }
        if (httpMethod !== "DELETE") options.body = data

        const res = await fetch(form.getAttribute("action"), options)
        if (res.ok) this.swap(await res.text())
    }

    showLoading(form) {
        const btn = form.querySelector("[type=submit]")
        if (btn && btn.dataset.loadingText) { btn.textContent = btn.dataset.loadingText; btn.disabled = true }
    }

    csrfToken() {
        const meta = document.querySelector("meta[name=csrf-token]")
        return meta ? meta.content : ""
    }
}
