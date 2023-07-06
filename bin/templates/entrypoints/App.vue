<script setup>
import dayjs from 'dayjs'
</script>

<script>
export default {
  data() {
    return {
      date: dayjs(),
      createdCount: 0,
    }
  },
  computed: {
    formatDate() {
      return this.date.format('YYYY-MM-DD')
    },
    pageDoneLoading() {
      return this.createdCount == 1
    },
  },
  created() {
    this.createdCount++
  },
}
</script>

<template>
  <h1 class="sample" data-cy="title">Template for %ENTRY_POINT% Entry Point</h1>
  <p>
    The current date is: <span>{{ formatDate }}</span>
  </p>

  <div data-cy="page-loaded" v-show="false">{{ pageDoneLoading }}</div>
</template>

<style scoped>
.sample {
  color: blue;
}
</style>
