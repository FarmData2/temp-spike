<template>
  <p>
    Counter from a component: {{ count }}
    <button @click="increment()">Increment</button>
  </p>
</template>

<script>
export default {
  name: 'CounterExample',
  data() {
    return {
      count: 0,
    }
  },
  methods: {
    increment() {
      this.count++
    },
  },
}
</script>
