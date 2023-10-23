<template>
  <div>
    Counter in a component: <span data-cy="count">{{ count }}</span>
    <br />
    <button
      data-cy="increment-button"
      @click="increment()"
    >
      Increment
    </button>
  </div>
</template>

<script>
export default {
  name: 'CounterExample',
  data() {
    return {
      count: 0,
    };
  },
  methods: {
    increment() {
      this.count++;
    },
  },
};
</script>
